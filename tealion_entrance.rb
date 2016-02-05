#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'socket'
require 'bundler'
require 'net/http'
#require 'json'
require 'open3'
#require_relative 'talker'
Bundler.require

HOST = "127.0.0.1"
APP_ROOT="#{ENV['TEALION_ROOT']}/tealion"

# 分割した必要なクラスファイルをインポート
require File.dirname(__FILE__) + "/Julius"
require File.dirname(__FILE__) + "/Rails"

rails = Rails.new()


julius = Julius.new(10500, "entrance.csv")
#Julius接続
s = julius.connectToJulius()

# main loop
while true
	# juliusから認識結果を受け取ったらrailsへアップロード
	ts, dispName = julius.receiveEntranceData(s)
	rails.send_json("#{ts} : 環境音(#{dispName})を認識しました")

end
