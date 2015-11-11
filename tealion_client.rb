#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'socket'
require 'bundler'
require 'net/http'
require 'json'
#require_relative 'talker'
Bundler.require

HOST = "192.168.100.107:3000"

def send_json(msg)
    src = "http://#{HOST}/log_views.json"
    uri = URI.parse(src)
    puts "send data to #{src}"
    user_id = 1
    time_out = 30
    begin
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
  rescue
    STDERR.puts "サーバへのデータ送信に失敗しました。"
  end
end

def connectToJulius
  #Juliusホスト、ポートの定義
  host = "localhost"
  port = 10500
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
  return s
end

def speak(status)
  voiceDir = "/tmp"
  statusList = {
    hello: "hellow.wav",
    handWash: "handWash.wav",
    question: "question.wav"
  }
  wavFile = voiceDir + "/" + statusList[status]
  unless File.exists?(wavFile)
    raise "指定された音声ファイルが存在しません。"
  end
  unless system("aplay #{wavFile}")
    raise "音声出力に失敗しました"
  end
end

def record
  recordDir = "/tmp"
  wavFile = recordDir + "/" + recordDir
  unless system("arecord #{wavFile}")
    raise "音声録音に失敗しました"
  end
  upload_wav wavFile
end

def upload_wav
  curlCmd = "curl -X POST -F wavFile=@#{wavFile} -F id=1 http://#{HOST}/uploaders"
  system("")
end

#検知する単語のリスト
wordList = [{
  sound: "handWash",
  dispWord:  "手洗い音"
  }]

#Julius接続
s = connectToJulius

#認識
source = ""
prev_t = {}
threshold = 60
while true
  begin
    ret = IO::select([s])
  rescue
    s = connectToJulius
    next
  end
  ret[0].each do |sock|
    source += sock.recv(65535)
    if source[-2..source.size] == ".\n"
      source.gsub!(/\.\n/, "")
      xml = Nokogiri(source)
      buff = (xml/"RECOGOUT"/"SHYPO"/"WHYPO").inject("") {|ws, w| ws + w["WORD"] }
      recogFlag = false
      unless buff == ""
        #puts buff
        wordList.each do |word|
          soundName = word[:sound]
          if buff =~ /#{soundName}/
            t = Time.now
            ts = t.strftime("%Y-%m-%d %H:%M")
            puts "recognized #{soundName}"
            next if prev_t.has_key?(soundName)
            prev_t[soundName] = ts
            send_json "#{ts} : #{soundName}を認識しました"
            recogFlag = true
            #speak :handWash
          end
        end
      end
      if recogFlag
        speak :question
        record
      end
      prev_t = {}
      source = ""
    end
  end
end
