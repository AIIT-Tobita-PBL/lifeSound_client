#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

CALLER = false

class Debug
	def initialize(flg)
		@debug_flg = flg
	end

	def print(msg)
		return if !@debug_flg

		if CALLER
			puts "debug.print(#{caller[0]}) : #{msg}"
		else
			puts "debug.print : #{msg}"
		end
	end
end
