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


	def checkLock(recog_sound, log_time)
	######################
	#
	# 施錠音がしたかチェック
	# 施錠音をもって帰宅したかどうかを判別する
	# 当然帰宅したか外出したか間違えたら間違え続ける
	#
	######################
		return	if @lock_flg
		if @sound_patterns[1] == recog_sound
			@debug.print("施錠音を認識")
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
		return if @lock_flg == false
		if @sound_patterns[1] == recog_sound
			@debug.print("施錠後のうがいを認識")

			if @ugai_flg == false
				@rails.send_json("#{ts} : 実績(うがい)")
				#@lock_flg = false
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
		#if t < Time.now() - 300
		#	
		#end

		if @lock_flg == true && @ugai_flg == false
			tmp = "忘れずにうがいをしてください"
			system("#{APP_ROOT}/bin/talk.sh #{tmp}")
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
			log_time = Time.local($1, $2, $3, $4, $5, 0)
			recog_sound = $6


			# 3分以上経過した施錠音のみフラグを立てる
			checkLock(recog_sound, log_time)

			# 施錠音のフラグあった場合のみ手洗いを確認する
			checkUgai(recog_sound, ts)
		end
	end


	def parse(t, ts)
	######################
	#
	# Juliusの認識結果を処理する部分
	#
	######################
		msgs = @db.sql()
		# メッセージが入っている配列全てをチェック
		msgs.each do |msg|
			#@debug.print("Juliusの認識結果そのまま#{msg}")
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
		t, ts = getTime()
		#while true
			parse(t, ts)
		#end
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
lifelog.finish()
