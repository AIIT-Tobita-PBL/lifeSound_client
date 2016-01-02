#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

class Debug
	def initialize(flg)
		@debug_flg = flg
	end

	def print(msg)
		if @debug_flg
			puts msg
		end
	end
end
