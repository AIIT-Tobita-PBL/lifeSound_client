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

require File.dirname(__FILE__) + "/Rails"
require File.dirname(__FILE__) + "/Voice"


rails = Rails.new()
voice = Voice.new()

voice.speak("question")
wavFile = voice.record
p "録音ファイル名:#{wavFile}"
rails.upload_wav(wavFile)
