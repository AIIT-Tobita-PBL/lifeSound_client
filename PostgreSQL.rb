#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

class PostgreSQL
	DEBUG_MODE = false
	require File.dirname(__FILE__) + "/Debug"

	require 'pg'

	def initialize()
		@debug = Debug.new(DEBUG_MODE)
	end

	def connect()
		@conn = PG::connect(
			host: "localhost",
			user: "pi",
			password: "pi",
			dbname: "lifeSoundLog_development"
		)
		#return conn
	end

	def sqlLifeLog(t)
	# log_viewsテーブルから記録の取得
		#t = Time.now - 360
		ts = t.strftime("%Y-%m-%d %H:%M")
		msgs = []

		begin
			result = @conn.exec(
				"SELECT * FROM log_views"\
				" WHERE updated_at > $1"\
				" ORDER BY updated_at ASC",
				[ts]
			)

			# 各行を処理する
			result.each do |tuple|
				msgs.push(tuple['msg'])
			end
		ensure
			return msgs
		end
	end

	def getMsg(msg)
		# questionsテーブルから保存されたメッセージの取得

		begin
			result = @conn.exec(
				"SELECT * FROM questions"\
				" WHERE updated_at >= $1"\
				" ORDER BY updated_at DESC",
				[msg["updated_at"]]
			)

			# 最新の保存メッセージのみ返す
			result.each do |tuple|
				msg = {
					"message" => tuple['message'],
					"updated_at" => tuple['updated_at'],
					"playFlag" => true
				}
			end
		ensure
				return msg
		end
	end

	# データベースへのコネクションを切断する
	def close()
 	 @conn.finish
	end
end
