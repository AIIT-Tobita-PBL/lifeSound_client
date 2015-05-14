#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'socket'
require 'bundler'
Bundler.require

#ホスト、ポートの定義
host = "localhost"
port = 10500

#検知する単語のリスト
wordList = ["handWash"]

s = nil
until s
  begin
    s = TCPSocket.open(host, port)
  rescue
    STDERR.puts "Julius に接続失敗しました\n再接続を試みます"
    sleep 10
    retry
  end
end
puts "Julius に接続しました"

source = ""
while true
  ret = IO::select([s])
  ret[0].each do |sock|
    source += sock.recv(65535)
    if source[-2..source.size] == ".\n"
      source.gsub!(/\.\n/, "")
      xml = Nokogiri(source)
      buff = (xml/"RECOGOUT"/"SHYPO"/"WHYPO").inject("") {|ws, w| ws + w["WORD"] }
      unless buff == ""
        #puts buff
        wordList.each do |word|
            if buff =~ /#{word}/
              puts "#{Time.now} : #{word}を認識しました"
            end
        end
      end
      source = ""
    end
  end
end
