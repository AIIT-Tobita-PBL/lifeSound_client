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
JULIUS_PORT = 10500
RAILS_PORT = 3000

APP_ROOT="#{ENV['HOME']}/tealion"

def send_json(msg)
    userId = 1
    params = {
        "log_view" =>{
            "user_id"=>userId,
            "msg"=>msg
        },
        "commit"=>"Create Log view"
    }.to_json
    curlCmd = "curl -H \"Accept: application/json\" -H \"Content-type: application/json\" -X POST -d '#{params}' http://#{HOST}:#{RAILS_PORT}/log_views.json"
    puts curlCmd #For debug
    stdout, stderr, status = Open3.capture3(curlCmd)
    if status != 0
        STDERR.puts "サーバへのデータ送信に失敗しました。"
    end
end

def connectToJulius
  #Juliusホスト、ポートの定義
  s = nil
  until s
    begin
      s = TCPSocket.open(HOST, JULIUS_PORT)
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
  voiceDir = "/tmp/tealion/speech"
  statusList = {
    hello: "hello.wav",
    handWash: "handWash.wav",
    question: "question.wav"
  }
  wavFile = voiceDir + "/" + statusList[status]
  unless File.exists?(wavFile)
    raise "指定された音声ファイルが存在しません。"
  end
  stdout, stderr, status = Open3.capture3("aplay #{wavFile}")
  p stdout
  p stderr
  p status
end

def record
  recordDir = "/tmp/tealion/record"
  wavFile = recordDir + "/wavFile.wav"

  stdout, stderr, status = Open3.capture3("ecasound -t:30 -i alsa -o #{wavFile}")
  p stdout
  p stderr
  p status
  upload_wav(wavFile)
end

def juliusControl(cmd)
  status = "do nothing"
  if cmd == "start" || cmd == "stop"
      juliusCmd = "#{APP_ROOT}/etc/init.d/julius #{cmd}"
      stdout, stderr, status = Open3.capture3(juliusCmd)
  end
  p status
  return status
end

def stopJulius(s)
    s.close
    juliusControl "stop"
end

def startJulius
    juliusControl "start"
end

def upload_wav(wavFile)
  curlCmd = "curl -X POST -F wavFile=@#{wavFile} -F id=1 http://#{HOST}:#{RAILS_PORT}/uploaders"
  system(curlCmd)
end

def receiveData(s)
    source = ""
    prev_t = {}
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
            @wordList.each do |word|
              soundName = word[:sound]
              dispName = word[:dispWord]
              askQuestion = word[:askQuestion]
              if buff =~ /#{soundName}/
                t = Time.now
                ts = t.strftime("%Y-%m-%d %H:%M")
                puts "recognized #{soundName}"
                next if prev_t.has_key?(soundName)
                prev_t[soundName] = ts
                send_json "#{ts} : #{dispName}を認識しました"
                if askQuestion
                    p "break the loop"
                    return
                end
              end
            end
          end
          prev_t = {}
          source = ""
        end
      end
    end
end



#検知する単語のリスト
@wordList = [{
  sound: "handWash",
  dispWord:  "手洗い音",
  askQuestion: true
}]

#Julius接続
s = connectToJulius
while true
    #認識
    receiveData(s)
    speak :question
    record
end
