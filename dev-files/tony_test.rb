Dir.chdir("..")

require 'bundler'
Bundler.require(:development, :default)

#   tt    [[[[ ]]]]
#   tt    [[     ]] nn nnn  yy   yy
#   tttt  [[     ]] nnn  nn yy   yy
#   tt    [[     ]] nn   nn  yyyyyy
#    tttt [[[[ ]]]] nn   nn      yy
#                            yyyyy

tony = Tony::VIBase.new
tony.handler_directory = "#{Dir.pwd}/lib/tony/handlers"
tony.load_handlers
tony.query! 'send a text to 8186208290 saying hmm'
