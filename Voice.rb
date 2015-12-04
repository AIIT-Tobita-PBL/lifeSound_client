#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

class Voice
	def record(wavFile)
		#recordDir = "/tmp/tealion/record"
		#wavFile = recordDir + "/wavFile.wav"
		#unixtime = Time.now.to_i
		#wavFile = recordDir + "/" + unixtime.to_s + ".wav"

		stdout, stderr, status = Open3.capture3("ecasound -t:10 -i alsa -o #{wavFile}")
		p stdout
		p stderr
		p status
		return wavFile
		#	unless system("arecord -d 10 #{wavFile}")
		#		raise "音声録音に失敗しました"
		#	end
	end

	def speak(status)
		voiceDir = "/tmp/tealion/speech"
		statusList = {
			"hello" => "hello.wav",
			"handWash" => "handWash.wav",
			"question" => "question.wav"
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
end
