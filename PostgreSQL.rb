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

	def sql(t)
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

	# データベースへのコネクションを切断する
	def close()
 	 @conn.finish
	end
end
