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


	def checkLock(recog_sound, logTime)
	######################
	#
	# 施錠音がしたかチェック
	# 施錠音をもって帰宅したかどうかを判別する
	# 当然帰宅したか外出したか間違えたら間違え続ける
	#
	######################
		# 施錠フラグが立ってない時のみ以降の処理を行う
		return	if @lock_flg

		if @sound_patterns[1] == recog_sound
			@debug.print("施錠音を認識")
			@lockTime = logTime

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
		# 施錠音フラグが立ってない場合は以降の処理は行わない
		return if @lock_flg == false

		if @sound_patterns[1] == recog_sound
			@debug.print("施錠後のうがいを認識")

			if @ugai_flg == false
				@rails.send_json("#{ts} : 実績(うがい)")
				@ugai_flg = true
			end
		end
	end


	def letUgai(t)
	######################
	#
	# うがいを促す
	#
	######################
		# 施錠フラグが立っており、
		# うがいフラグが立ってない場合のみ
		# 以降の処理をおこなう
		if @lock_flg == true && @ugai_flg == false

			# 施錠音フラグが立った時刻から
			# ５分以上経過した場合のみ
			# うがいを促す
			return if @lockTime < t - 300
			tmp = "忘れずにうがいをしてください"
			system("#{APP_ROOT}/bin/talk.sh #{tmp}")
			@ugai_flg = true
		end
	end


	def lifeSound(msg, ts)
	######################
	#
	# 環境音をチェックする
	# 施錠音の後、5分以内にうがいがないとうがいを促す
	# うがいしていた場合は実績をrailsに残す
	#
	######################
		if(msg =~ /(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}) : 環境音\((.*)\)を認識しました/)
			logTime = Time.local($1, $2, $3, $4, $5, 0)
			recog_sound = $6


			# 施錠音のチェック
			checkLock(recog_sound, logTime)

			# 施錠音のフラグあった場合のみ手洗いを確認する
			checkUgai(recog_sound, ts)
		end
	end


	def parse(t, ts, lastTime)
	######################
	#
	# Juliusの認識結果を処理する部分
	#
	######################
		msgs = @db.sql(lastTime)
		# メッセージが入っている配列全てをチェック
		msgs.each do |msg|
			#@debug.print("PostgreSQLのレコードそのまま(#{msg})")
			# 環境音のチェック
			lifeSound(msg, ts)
		end

		# 施錠音のフラグが立っていて手洗い音のフラグがない場合はうがいを促す
		letUgai(t)
	end


	def run()
	######################
	#
	# main loop
	#
	######################
		lastTime = Time.now() - 300
		while true
			# 現在時刻を取得して、前回の解析時刻以降のdbの記録を解析
			t, ts = getTime()
			parse(t, ts, lastTime)

			# 前回解析した時刻として保存
			lastTime = t

			# 1秒sleepをしてからloop
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
# 上でloopが回っているのでここには来ない
# ctrl+cで止める処理を書いた時に利用する予定
lifelog.finish()
