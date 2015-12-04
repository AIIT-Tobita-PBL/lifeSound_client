#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

recordDir = "/tmp/tealion/record"
wavFile = recordDir + "/wavFile.wav"

# 録音ファイルが存在したら処理を停止
if File.exist?(wavFile) then
	p "#{wavFile}が存在するため録音はスキップします"
	exit!
end
FileUtils.touch(wavFile)

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

require File.dirname(__FILE__) + "/Rails"
require File.dirname(__FILE__) + "/Voice"


rails = Rails.new()
voice = Voice.new()

voice.speak("question")

# 30秒録音してrailsへアップロード
p "#{wavFile}へ録音中"
voice.record(wavFile)
rails.upload_wav(wavFile)

# 録音ファイルの削除
File.unlink wavFile
