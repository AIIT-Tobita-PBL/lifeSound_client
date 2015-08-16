#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'json'
require 'date'

class Talker
  #コンストラクタ
  ##引数:
  # charType : 音声のキャラクタータイプの指定
  #            (※キャラクターごとの音声ファイルは、/opt/talker/wavFiles/[キャラクター名]に配置しておくこと)
  def initialize(charType="male")
    @voiceDataBaseDir = "/opt/talker/wavFiles"
    @voiceDataList = {
        goodMorning: "ohayo.wav",
        goodAfternoon: "konnnichiwa.wav",
        goodEvening: "konbanwa.wav",
        goodNight: "oyasuminasai.wav",
        welcomeBack: "okaerinasai",
        lonely: "samishii.wav",
        handWash: "te_aratta.wav"
    }
    @voiceDataPath = @voiceDataBaseDir + "/" + charType
    unless File.directory?(@voiceDataPath)
      raise "指定されたキャラクターの音声ファイルが存在しません。"
    end
  end

  #台詞の決定（時間での選択）
  def selectVoiceByTime()
    h = DateTime.now.hour
    morning, noon, evening, welcomeBack, night =
      [5, 6, 7, 8, 9, 10],
      [11, 12, 13, 14, 15, 16],
      [17, 18, 19],
      [20, 21],
      [22, 23, 0, 1, 2, 3, 4]
    word =
      case h
      when *morning
        :goodMorning
      when *noon
        :goodAfternoon
      when *evening
        :goodEvening
      when *welcomeBack
        :welcomeBack
      when *night
        :goodNight
      else
        :evening
      end
  end

  #音声認識時の台詞の決定
  #認識した音の種類で音声を分けるべきだが、とりあえず手洗い音のみ
  def selectVoiceIfRecognized(recognizedSound)
    return :handWash
  end

  #スケジュールに従った発話の台詞決定
  def selectVoiceBySchedule(pt)
    t = Time.now
    threshold = 2 * 60 * 60
    word = nil
    word = :lonely if (t - pt).to_i > threshold
  end

  #aplayで話す
  def talk(word)
    wavFile = @voiceDataPath + "/" + @voiceDataList[word]
    unless File.exists?(wavFile)
      raise "指定された音声ファイルが存在しません。"
    end
    unless system("aplay #{wavFile}")
      raise "音声出力に失敗しました"
    end
  end
end
