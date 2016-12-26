require_relative 'dialoginterface'
require_relative 'smsinterface'
require_relative 'consoleinterface'
require_relative 'vibase'
require_relative 'queryhandler'

# TTTTTTT [[[[ ]]]]                 
#   TTT   [[     ]] nn nnn  yy   yy 
#   TTT   [[     ]] nnn  nn yy   yy 
#   TTT   [[     ]] nn   nn  yyyyyy 
#   TTT   [[[[ ]]]] nn   nn      yy 
#                            yyyyy  


tony = VIBase.new()
tony.name = "Tony"
tony.interface = ConsoleInterface.new()
tony.load_handlers
puts tony.list_handlers