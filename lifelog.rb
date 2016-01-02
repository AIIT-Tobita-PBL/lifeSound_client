#! /usr/bin/env ruby
# -*- coding: utf-8 -*-


require File.dirname(__FILE__) + "/Rails"
require File.dirname(__FILE__) + "/Debug"
require File.dirname(__FILE__) + "/PostgreSQL"

DEBUG_MODE = true

APP_ROOT="#{ENV['TEALION_ROOT']}"


def parse(msgs)
	debug = Debug.new(DEBUG_MODE)

	sound_patterns = [
		"施錠音",
		"手洗い音"
	]

	lock_flg = false
	ugai_flg = false

	msgs.each do |msg|
		debug.print(msg)
		if(msg =~ /(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}) : 環境音\((.*)\)を認識しました/)
			log_time = Time.local($1, $2, $3, $4, $5, 0)
			t = Time.now()
			ts = t.strftime("%Y-%m-%d %H:%M")

			recog_sound = $6

			# 3分以上経過した施錠音のみフラグを立てる
			if sound_patterns[0] == recog_sound && log_time < t - 300 then
				lock_flg = true
				debug.print("lock")
			end

			# 施錠音のフラグあった場合のみ手洗いを確認する
			if sound_patterns[1] == recog_sound && lock_flg then
				debug.print("ugai")

				if ugai_flg == false
					rails = Rails.new()
					rails.send_json("#{ts} : 実績(うがい)")
					ugai_flg = true
				end
			end
		end
	end

	# 施錠音のフラグが立っていて手洗い音のフラグがない場合はうがいを促す
	if lock_flg == true && ugai_flg == false
		tmp = "忘れずにうがいをしてください"
		system("#{APP_ROOT}/bin/talk.sh #{tmp}")
	end
end


db = PostgreSQL.new()
db.connect()
msgs = db.sql()
parse(msgs)
db.close()
