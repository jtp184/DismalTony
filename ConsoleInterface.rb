require_relative 'dialoginterface'

class ConsoleInterface < DialogInterface
	def send msg
		puts msg
	end

	def recieve 
		return gets
	end
end