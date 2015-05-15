#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'socket'
require 'bundler'
require 'net/http'
require 'json'
Bundler.require

def send_json(msg)
    uri = URI.parse('http://127.0.0.1:3000/log_views.json')
    user_id = 1
    time_out = 30

    Net::HTTP.start(uri.host, uri.port) do |http|
      #リクエストインスタンス生成
      request = Net::HTTP::Post.new(uri.path)
      request["user-agent"] = "Ruby/#{RUBY_VERSION} MyHttpClient"
      request["Content-Type"] = "application/json"
      payload = {
        "log_view" =>{
          "user_id"=>user_id,
          "msg"=>msg
        },
        "commit"=>"Create Log view"
      }.to_json
      request.body = payload
      #time out
      http.open_timeout = time_out
      http.read_timeout = time_out

      #送信
      response = http.request(request)
      p "====RESULT(#{uri.host})========"
      p "==> "+response.body
    end
end

#Juliusホスト、ポートの定義
host = "localhost"
port = 10500

#検知する単語のリスト
wordList = [{
  sound: "handWash",
  dispWord:  "手洗い音"
  }]

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
            if buff =~ /#{word[:sound]}/
              t = Time.now.strftime("%Y-%m-%d %H:%M")
              send_json "#{t} : #{word[:dispWord]}を認識しました"
            end
        end
      end
      source = ""
    end
  end
end
