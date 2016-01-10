require_relative '../talker'

talker = Talker.new
words = []

puts "1. test for selectVoiceByTime"
w = talker.selectVoiceByTime
puts "selected word: #{w}"
words.push(w)

puts "2. test for selectVoiceIfRecognized"
w = talker.selectVoiceIfRecognized("handWash")
puts "selected word: #{w}"
words.push(w)

puts "3. test for talk"
words.each{|w|talker.talk(w)}
