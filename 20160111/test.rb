#! /usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'socket'
require 'bundler'
require 'net/http'
require 'json'
require 'open3'
#require_relative 'talker'
Bundler.require

HOST = "localhost"
JULIUS_PORT = 10500


class JuliusConnector < EM::Connection
  @@reconnectInterval = 5
  def initialize(juliusHost, juliusPort)
    @juliusHost = juliusHost
    @juliusPort = juliusPort
  end

  def post_init
    puts "Juliusに接続しました #{@juliusHost}:#{@juliusPort}"
  end

  def receive_data(data)

  end

  def unbind
    puts "接続がクローズしました。 #{@juliusHost}:#{@juliusPort}"
    puts "再接続します..."
    EM::add_timer(@@reconnectInterval) do
      reconnect(@juliusHost,  @juliusPort)
    end
  end

  def juliusControl(cmd)
    xml =
        case cmd
        when :pause
            "<STOPPROC/>\n"
        when :resume
            "<STARTPROC/>\n"
        else
            "\n"
        end
    send_data(xml)
  end
end

class Test < JuliusConnector
   def post_init
     super
     juliusControl :pause
   end
end

puts "Julius起動中..."
conf = "/home/tobby/tealion/share/julius_files/lifeSound.jconf"
system("nohup julius -C #{conf} -input mic -module &")

EM.run do
  EM.connect(HOST, JULIUS_PORT, Test, HOST, JULIUS_PORT)
end
