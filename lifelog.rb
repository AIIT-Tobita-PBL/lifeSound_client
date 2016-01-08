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
			"手洗い音",
			"うがい音"
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


	def checkLock(recog_sound, t)
	######################
	#
	# 施錠音がしたかチェック
	# 施錠音をもって帰宅したかどうかを判別する
	# 当然帰宅したか外出したか間違えたら間違え続ける
	#
	######################
		# 施錠音のフラグが立っている時は処理しないで抜ける
		return if @lock_flg

		if @sound_patterns[1] == recog_sound
			@debug.print("施錠音を認識")
			# 施錠音を認識した時刻を保存
			@lock_time = t

			# フラグ処理
			@lock_flg = !@lock_flg
			@ugai_flg = false
		end
	end


	def checkUgai(recog_sound, ts)
	######################
	#
	# うがいをしたかチェック
	#
	######################
		# 施錠音のフラグが立っていない時は処理しないで抜ける
		return if @lock_flg == false

		# うがい音のフラグが立っていた時は処理しないで抜ける
		return if @ugai_flg

		if @sound_patterns[1] == recog_sound
			@debug.print("施錠後のうがいを認識")
			# railsに実績を残す
			@rails.send_json("#{ts} : 実績(施錠後、５分以内のうがい)")

			# フラグ
			#@lock_flg = false
			@ugai_flg = true

		end
	end


	def letUgai(t)
	######################
	#
	# うがいを促す
	#
	######################
		# 施錠音が記録されており、うがい音がまだ記録されていない時のみ処理
		if @lock_flg == true && @ugai_flg == false
			# 施錠音の記録から5分経過した場合のみ以降を処理
			return if @lock_time < t - 300

			# うがいを促す発声
			tmp = "忘れずにうがいをしてください"
			system("#{APP_ROOT}/bin/talk.sh #{tmp}")
		end
	end


	def checkLifeSound(msg, t, ts)
	######################
	#
	# 環境音をチェックする
	# 施錠音の後、5分以内にうがいがないとうがいを促す
	# うがいしていた場合は実績をrailsに残す
	#
	######################
		if(msg =~ /(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}) : 環境音\((.*)\)を認識しました/)
			#log_time = Time.local($1, $2, $3, $4, $5, 0)
			recog_sound = $6


			# 施錠音の確認
			checkLock(recog_sound, t)

			# 手洗い音の確認
			checkUgai(recog_sound, ts)
		end
	end


	def parse(t, ts, last_time)
	######################
	#
	# Juliusの認識結果を処理する部分
	#
	######################
		msgs = @db.sql(last_time)
		# メッセージが入っている配列全てをチェック
		msgs.each do |msg|
			#@debug.print("PostgreSQLのレコード(#{msg})")
			# 環境音のチェック
			checkLifeSound(msg, t, ts)
		end

		# うがいを促す
		letUgai(t)
	end


	def run()
	######################
	#
	# main loop
	#
	######################
		last_time = Time.now() - 300

		while true
			# 現在時刻を取得
			t, ts = getTime()

			# DBの記録を確認
			parse(t, ts, last_time)

			# 前回時刻を保存
			last_time = t

			# 1秒スリープしてloop
			sleep(1)
		end
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
lifelog.run()

# 終了処理
# main loopを抜けないので基本的にここには来ない
# ctrl−cで抜けた処理を書く時のために残しておく
lifelog.finish()
