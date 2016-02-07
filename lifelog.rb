#! /usr/bin/env ruby
# -*- coding: utf-8 -*-



DEBUG_MODE = true

APP_ROOT="#{ENV['TEALION_ROOT']}"


class LifeLog
	require "csv"
	require File.dirname(__FILE__) + "/PostgreSQL"
	require File.dirname(__FILE__) + "/Rails"
	require File.dirname(__FILE__) + "/Debug"

	def initialize()
		@rails = Rails.new()
		@debug = Debug.new(DEBUG_MODE)

		# postgeSQLのコネクション作成
		@db = PostgreSQL.new()
		@db.connect()

		@types = {
			"lifeSound" => "環境音",
			"voice" => "発話",
			"result" => "実績"
		}

		@voiceList=getCSV("voice.csv")

		@sound_patterns = {
			"handWash" => "手洗い音",
			"mouthWash" => "うがい音",
			"ugai" => "うがい音",
			"entrance_lock" => "ロック音"
		}

		@lock_flg = false
		@ugai_flg = false
		@handSoap_flg = false

		@msg = {
			"message" => "",
			"updated_at" => "2015-01-01 00:00:00",
			"playFlag" => false
		}
	end

	def getTime()
	######################
	#
	# 現在時刻を取るだけ
	#
	######################
		t = Time.now()
		ts = t.strftime("%Y-%m-%d %H:%M:%S")
		return [t,ts]
	end


  def getCSV(csvFile)
  # csvファイルの取得
    wordList =[]
    header, *body = CSV.read(csvFile)
      body.each do |row|
       wordList.push(header[1]=>row[1], header[2]=>row[2])
    end
    return wordList
  end

	def checkLock(type, recog_sound, logTime)
	######################
	#
	# ロック音がしたかチェック
	# ロック音をもって帰宅したかどうかを判別する
	# 当然帰宅したか外出したか間違えたら間違え続ける
	#
	######################
		# 環境音出なかった場合は抜ける
		return if @types["lifeSound"] != type
		# ロックフラグが立ってない時のみ以降の処理を行う
		return	if @lock_flg

		if @sound_patterns["entrance_lock"] == recog_sound
			@debug.print("ロック音を認識")
			@lockTime = logTime

			# フラグ処理
			@lock_flg = !@lock_flg
			@ugai_flg = false
			@handSoap_flg = false
		end
	end


	def checkUgai(type, recog_sound, ts)
	######################
	#
	# うがいをしたかチェック
	#
	######################
		# 環境音でなかった場合は抜ける
		return if @types["lifeSound"] != type
		# ロック音フラグが立ってない場合は以降の処理は行わない
		return if @lock_flg == false

		if @sound_patterns["mouthWash"] == recog_sound
			@debug.print("ロック後のうがいを認識")

			if @ugai_flg == false
				@rails.send_json("#{ts} : 実績(うがい)")
				@ugai_flg = true
			end
		end
	end


	def checkHandSoap(type, recog_sound, ts)
	######################
	#
	# 手洗い石鹸を使ったかチェック
	#
	######################
		# 実績でなかった場合は抜ける
		return if @types["result"] != type
		# ロック音フラグが立ってない場合は以降の処理は行わない
		return if @lock_flg == false

		if "石鹸を使いました。" == recog_sound
			@debug.print("ロック後の手洗い石鹸の使用を認識")

			if @handSoap_flg == false
				@rails.send_json("#{ts} : 実績(ロック後の手洗い石鹸の使用)")
				@handSoap_flg = true
			end
		end
	end


	def letUgai(t)
	######################
	#
	# うがいを促す
	#
	######################
		# ロックフラグが立っており、
		# うがいフラグが立ってない場合のみ
		# 以降の処理をおこなう
		if @lock_flg == true && @ugai_flg == false

			# ロック音フラグが立った時刻から
			# ５分以上経過した場合のみ
			# うがいを促す
			return if @lockTime < t - 300
			tmp = "帰宅してから5分経過しました。忘れずにうがいを行ってください。"
			system("#{APP_ROOT}/bin/talk.sh #{tmp}")
			sleep(7)
			@ugai_flg = true
		end
	end


	def lifeSound(log, ts)
	######################
	#
	# 環境音をチェックする
	# ロック音の後、5分以内にうがいがないとうがいを促す
	# うがいしていた場合は実績をrailsに残す
	#
	######################
		if(log =~ /(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2}) : (.*)\((.*)\)を認識しました/)
			logTime = Time.local($1, $2, $3, $4, $5, $6)
			type = $7
			recog_sound = $8

			# 環境音でなかった場合は抜ける
			#return if @types["lifeSound"] != type

			# ロック音のチェック
			checkLock(type, recog_sound, logTime)

			# ロック音のフラグあった場合のみ手洗いを確認する
			checkUgai(type, recog_sound, ts)

			return [type, recog_sound]
		end

		# 石鹸対応
		if(log =~ /(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2}) : 石鹸を使いました。/)
			logTime = Time.local($1, $2, $3, $4, $5, $6)
			type = "実績"
			recog_sound = "石鹸を使いました。"

			# ロック音のフラグあった場合のみ手洗い石鹸を確認する
			checkHandSoap(type, recog_sound, ts)

		end
	end


	def logParse(t, ts, lastTime)
	######################
	#
	# Juliusの認識結果を処理する部分
	#
	######################
		# log_viewsテーブルから記録を取得
		msgs = @db.sqlLifeLog(lastTime)
		#@debug.print("PostgreSQLのレコードそのまま(#{msgs})")
		# 記録が入っている配列全てをチェック
		type=""
		recog_sound = ""
		msgs.each do |log|
			# 環境音のチェック
			type, recog_sound = lifeSound(log, ts)
		end

		# 記録が複数だった場合はイベントを書き換え
		if msgs.length >= 2
			type = @types["lifeSound"]
			recog_sound = "#{msgs.length}件のイベント"
		end

		# 話しかけられていた場合の処理
		talk(msgs.length, type, recog_sound)

		# 認識した環境音を伝える
		recog_lifeSound(msgs.length, type, recog_sound)

		# 保存されていたメッセージの再生
		play(msgs.length)

		# ロック音のフラグが立っていて手洗い音のフラグがない場合はうがいを促す
		letUgai(t)
	end

	def getMsg()
		# 保存されたメッセージの取得
		@msg = @db.getMsg(@msg)
	end


	def recog_lifeSound(event_count, type, recog_sound)
	# 認識した環境音を伝える
		if event_count >= 1 && @types["lifeSound"] == type
			tmp = "#{recog_sound}を認識しました。"
			if event_count == 1
				tmp = tmp + "いいね！"
			end
			@debug.print(tmp)
			system("#{APP_ROOT}/bin/talk.sh #{tmp}")
			sleep(6)
		end
	end


	def play(event_count)
	# 保存されていたメッセージの再生
		return if event_count < 1

		if @msg["playFlag"]
			tmp = "メッセージがあります。メッセージを再生します。"
			@debug.print(tmp)
			system("#{APP_ROOT}/bin/talk.sh #{tmp}")
			sleep(7)
			system("#{APP_ROOT}/bin/talk.sh #{@msg["message"]}")
			sleep(6)
			tmp = "メッセージは以上です。メッセージへの返答を記録します。"
			system("#{APP_ROOT}/bin/talk.sh #{tmp}")
			sleep(7)
			system("ruby record.rb")
			sleep(6)
			tmp = "返答を記録しました。"
			system("#{APP_ROOT}/bin/talk.sh #{tmp}")
			@msg["playFlag"] = false
			sleep(6)
		end
	end


	def talk(event_count, type, recog_sound)
	# 発話機能
		if event_count == 1 && @types["voice"] == type
			tmp = "今の発言は、#{recog_sound}、ですね。"
			@voiceList.each do |word|
				dispWord = word["dispWord"]
				answer = word["answer"]
				if recog_sound =~ /#{dispWord}/
					tmp += "#{answer}"
				end
			end
			@debug.print(tmp)
			system("#{APP_ROOT}/bin/talk.sh #{tmp}")
			sleep(5)
		end
	end

	def run()
	######################
	#
	# main loop
	#
	######################
		lastTime = Time.now() - 300
		while true
			# 保存されたメッセージを取得
			getMsg()

			# 現在時刻を取得して、前回の解析時刻以降のdbの記録を解析
			t, ts = getTime()
			logParse(t, ts, lastTime)

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
