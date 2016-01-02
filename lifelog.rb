#! /usr/bin/env ruby
# -*- coding: utf-8 -*-



DEBUG_MODE = true

APP_ROOT="#{ENV['TEALION_ROOT']}"


class LifeLog
	require File.dirname(__FILE__) + "/PostgreSQL"
	require File.dirname(__FILE__) + "/Rails"
	require File.dirname(__FILE__) + "/Debug"

	def initialize()
		@rails = Rails.new()
		@debug = Debug.new(DEBUG_MODE)

		# postgeSQLのコネクション作成
		@db = PostgreSQL.new()
		@db.connect()

		@sound_patterns = [
			"施錠音",
			"手洗い音"
		]

		@lock_flg = false
		@ugai_flg = false
	end

	def getTime()
	######################
	#
	# 現在時刻を取るだけ
	#
	######################
		t = Time.now()
		ts = t.strftime("%Y-%m-%d %H:%M")
		return [t,ts]
	end


	def checkLock(recog_sound, log_time, t)
	######################
	#
	# 施錠音がしたかチェック
	# 施錠音をもって帰宅したかどうかを判別する
	# 当然帰宅したか外出したか間違えたら間違え続ける
	#
	######################
		if @sound_patterns[1] == recog_sound && log_time < t - 300 then
			@lock_flg = true
			@debug.print("lock")
		end
	end


	def checkUgai(recog_sound, ts)
	######################
	#
	# うがいをしたかチェック
	#
	######################
		if @sound_patterns[1] == recog_sound && @lock_flg then
			@debug.print("ugai")

			if @ugai_flg == false
				@rails.send_json("#{ts} : 実績(うがい)")
				@ugai_flg = true
			end
		end
	end


	def letUgai()
	######################
	#
	# うがいを促す
	#
	######################
		if @lock_flg == true && @ugai_flg == false
			tmp = "忘れずにうがいをしてください"
			system("#{APP_ROOT}/bin/talk.sh #{tmp}")
		end
	end


	def lifeSound(msg)
	######################
	#
	# 環境音をチェックする
	# 施錠音の後、5分以内にうがいがないとうがいを促す
	# うがいしていた場合は実績をrailsに残す
	#
	######################
		if(msg =~ /(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}) : 環境音\((.*)\)を認識しました/)
			log_time = Time.local($1, $2, $3, $4, $5, 0)
			recog_sound = $6

			t, ts = getTime()

			# 3分以上経過した施錠音のみフラグを立てる
			checkLock(recog_sound, log_time, t)

			# 施錠音のフラグあった場合のみ手洗いを確認する
			checkUgai(recog_sound, ts)
		end
	end


	def parse()
		msgs = @db.sql()
		# メッセージが入っている配列全てをチェック
		msgs.each do |msg|
			@debug.print(msg)
			# 環境音のチェック
			lifeSound(msg)
		end

		# 施錠音のフラグが立っていて手洗い音のフラグがない場合はうがいを促す
		letUgai()
	end


	def finish()
		# postgreSQLを切断
		@db.close()
	end
end


# 初期化
lifelog = LifeLog.new()


######################
#
# main loop
#
######################
lifelog.parse()


# 終了処理
lifelog.finish()
