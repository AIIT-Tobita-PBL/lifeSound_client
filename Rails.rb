#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

class Rails
	RAILS_PORT = 3000

	def record
		recordDir = "/tmp/tealion/record"
		wavFile = recordDir + "/wavFile.wav"

		stdout, stderr, status = Open3.capture3("ecasound -t:30 -i alsa -o #{wavFile}")
		p stdout
		p stderr
		p status
		upload_wav(wavFile)
	end


	def upload_wav(wavFile)
		curlCmd = "curl -X POST -F wavFile=@#{wavFile} -F id=1 http://#{HOST}:#{RAILS_PORT}/uploaders"
		system(curlCmd)
	end

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
end
