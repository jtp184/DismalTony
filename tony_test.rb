require_relative 'dialoginterface'
require_relative 'smsinterface'
require_relative 'consoleinterface'
require_relative 'vibase'
require_relative 'queryhandler'

#   tt    [[[[ ]]]]                 
#   tt    [[     ]] nn nnn  yy   yy 
#   tttt  [[     ]] nnn  nn yy   yy 
#   tt    [[     ]] nn   nn  yyyyyy 
#    tttt [[[[ ]]]] nn   nn      yy 
#                            yyyyy  

tony = VIBase.new()
tony.query! "message 8186208290 saying ~e:wave Hello!"
# tony.interface = SMSInterface.new
# tony.interface.destination = '+18186208290'
# tony.list_handlers
# tony.query! "text 8186208290 saying hello"