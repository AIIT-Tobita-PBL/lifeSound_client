#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'socket'
require 'bundler'
require 'net/http'
require 'json'
require 'open3'
#require_relative 'talker'
Bundler.require

#HOST = "192.168.100.107:3000"
HOST = "127.0.0.1"

APP_ROOT="#{ENV['HOME']}/tealion"

# 分割した必要なクラスファイルをインポート
require File.dirname(__FILE__) + "/Julius"
require File.dirname(__FILE__) + "/Rails"


rails = Rails.new()
julius = Julius.new()

#Julius接続
s = julius.connectToJulius()

while true
	# juliusから認識結果を受け取ったらrailsへアップロード
	ts, dispName = julius.receiveData(s)
	rails.send_json("#{ts} : #{dispName}を認識しました")
	
	# 10秒間録音してrailsへアップロード
	# 録音中は二重起動しない(ヘッポコ)
	system("ruby record.rb &")
end
