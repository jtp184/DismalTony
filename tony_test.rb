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
tony.interface.color_on = true
tony.say "Hello!"