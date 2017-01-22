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
tony.load_handlers! "#{Dir.pwd}/lib/tony/handlers"
puts print tony.list_handlers
tony.query! 'hello'
