require_relative 'dialoginterface'
module Tony
class String
	def black;          "\e[30m#{self}\e[0m" end
	def red;            "\e[31m#{self}\e[0m" end
	def green;          "\e[32m#{self}\e[0m" end
	def brown;          "\e[33m#{self}\e[0m" end
	def blue;           "\e[34m#{self}\e[0m" end
	def magenta;        "\e[35m#{self}\e[0m" end
	def cyan;           "\e[36m#{self}\e[0m" end
	def gray;           "\e[37m#{self}\e[0m" end

	def bg_black;       "\e[40m#{self}\e[0m" end
	def bg_red;         "\e[41m#{self}\e[0m" end
	def bg_green;       "\e[42m#{self}\e[0m" end
	def bg_brown;       "\e[43m#{self}\e[0m" end
	def bg_blue;        "\e[44m#{self}\e[0m" end
	def bg_magenta;     "\e[45m#{self}\e[0m" end
	def bg_cyan;        "\e[46m#{self}\e[0m" end
	def bg_gray;        "\e[47m#{self}\e[0m" end

	def bold;           "\e[1m#{self}\e[22m" end
	def italic;         "\e[3m#{self}\e[23m" end
	def underline;      "\e[4m#{self}\e[24m" end
	def blink;          "\e[5m#{self}\e[25m" end
	def reverse_color;  "\e[7m#{self}\e[27m" end
end

class ConsoleInterface < DialogInterface
	attr_accessor :color_on
	def send msg
		str = msg
		if(@color_on)
			pt = /(\[).+(\])(:) (.+)/
			md = (pt.match msg)

			str = str.gsub(md[1], colorize(md[1], @colors["l_bracket"]))
			str = str.gsub(md[2], colorize(md[2], @colors["r_bracket"]))
			# str = str.gsub(md[3], colorize(md[3], @colors["colon"]))
			str = str.gsub(md[4], colorize(md[4], @colors["message"]))
		end
		puts str
	end

	def initialize()
		@color_on = false
		@colors = {
			"l_bracket" => "cyan",
			"r_bracket" => "cyan",
			"colon" => "yellow",
			"message" => "red",
		}
	end

	def colorize str, col
		colors = {
			"red" => str.red,
			"green" => str.green,
			"brown" => str.brown,
			"blue" => str.blue,
			"magenta" => str.magenta,
			"cyan"  => str.cyan,
			"gray"  => str.gray
		}
		return colors[col]
	end

	def recieve 
		return gets
	end

	def color toggle
		@color_on = toggle
	end
end
end