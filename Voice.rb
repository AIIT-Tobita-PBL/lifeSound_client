#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

class Voice
	def record
		recordDir = "/tmp/tealion/record"
		wavFile = recordDir + "/wavFile.wav"

		stdout, stderr, status = Open3.capture3("ecasound -t:30 -i alsa -o #{wavFile}")
		p stdout
		p stderr
		p status
		return wavFile
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
