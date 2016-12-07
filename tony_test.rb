require_relative 'dialoginterface'
require_relative 'smsinterface'
require_relative 'consoleinterface'
require_relative 'aibase'
require_relative 'queryhandler'

tony = AIBase.new()
tony.name = "Tony"
tony.interface = ConsoleInterface.new()
tony.load_handlers
puts tony.list_handlers