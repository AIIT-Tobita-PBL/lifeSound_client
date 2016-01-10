#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'socket'
require 'bundler'
require 'net/http'
#require 'json'
require 'open3'
#require_relative 'talker'
Bundler.require

#HOST = "192.168.100.107:3000"
HOST = "127.0.0.1"

#APP_ROOT="#{ENV['HOME']}/tealion"
APP_ROOT="#{ENV['TEALION_ROOT']}"

# 分割した必要なクラスファイルをインポート
require File.dirname(__FILE__) + "/Julius-voice"
require File.dirname(__FILE__) + "/Rails"


rails = Rails.new()
julius = Julius.new()

#Julius接続
s = julius.connectToJulius()

while true
	# juliusから認識結果を受け取ったらrailsへアップロード
	ts, listening = julius.receiveData(s)
	rails.send_json("#{ts} : 発話(#{listening})を認識しました")
end
