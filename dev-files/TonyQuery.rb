require_relative 'dialoginterface'
require_relative 'smsinterface'
require_relative 'consoleinterface'
require_relative 'vibase'
require_relative 'queryhandler'

args = ARGV
@interface_string = args.reverse.pop
args.delete(@interface_string)
@return_interface = ConsoleInterface.new()
if(@interface_string =~ /tel:\+\d+/)
	@return_interface = SMSInterface.new((/tel:(\+\d+)/.match @interface_string)[1])
end
tony = VIBase.new("Tony", @return_interface)
tony.query! args.join(" ")