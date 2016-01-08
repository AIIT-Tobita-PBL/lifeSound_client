#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'socket'
require 'bundler'
require 'net/http'
#require 'json'
require 'open3'
#require_relative 'talker'
Bundler.require

#デバイスの役割
#現状、handWash(手洗い音)かmouthWash(うがい)を選択可能
#ROLE = "handWash"
ROLE = "mouthWash"
#ROLE = "entrance_lock"
#HOST = "192.168.100.107:3000"
HOST = "127.0.0.1"
APP_ROOT="#{ENV['HOME']}/tealion"

# 分割した必要なクラスファイルをインポート
require File.dirname(__FILE__) + "/Julius"
require File.dirname(__FILE__) + "/Rails"

#動作制御フラグ
record = false

rails = Rails.new()
julius = Julius.new(ROLE)

#Julius接続
s = julius.connectToJulius()

while true
	# juliusから認識結果を受け取ったらrailsへアップロード
	ts, dispName = julius.receiveData(s)
	rails.send_json("#{ts} : 環境音(#{dispName})を認識しました")

	# 10秒間録音してrailsへアップロード
	# 録音中は二重起動しない(ヘッポコ処理でロックが不十分なのでいつか治す)
	if record
		system("ruby record.rb &")
	end
end
