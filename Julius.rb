#! /usr/bin/env ruby
# -*- coding: utf-8 -*-


class Julius
	DEBUG_MODE = true
	require File.dirname(__FILE__) + "/Debug"

	JULIUS_PORT = 10500


	# 初期化処理
	def initialize()

		@debug = Debug.new(DEBUG_MODE)
		@wordList = [
			{
				sound: "handWash",
				dispWord:  "手洗い音"
			},{
				sound: "ugai",
				dispWord:  "うがい音"
			},{
				sound: "entrance_lock",
				dispWord:  "施錠音"
			}
		]

	end

	# juliusへ接続
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

	# juliusから認識結果を受信
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
						@debug.print(buff)
						@wordList.each do |word|
							soundName = word[:sound]
							dispName = word[:dispWord]
							if buff =~ /#{soundName}/
								t = Time.now
								ts = t.strftime("%Y-%m-%d %H:%M")
								puts "recognized #{soundName}"

								p "break the loop"
								return ts,dispName
							end
						end
					end
					source = ""
				end
			end
		end
	end

	# juliusのサービスコントロール用(今は使用していない)
	def juliusControl(cmd)
		status = "do nothing"
		if cmd == "start" || cmd == "stop"
			juliusCmd = "#{APP_ROOT}/etc/init.d/julius #{cmd}"
			stdout, stderr, status = Open3.capture3(juliusCmd)
		end
		p status
		return status
	end

	# juliusサービスの停止(今は使用していない)
	def stopJulius(s)
		s.close
		juliusControl "stop"
	end

	# juliusサービスのスタート(今は使用していない)
	def startJulius
		juliusControl "start"
	end

end
