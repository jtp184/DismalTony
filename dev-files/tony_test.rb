Dir.chdir("..")

require 'bundler'
Bundler.require(:development, :default)

#   tt    [[[[ ]]]]
#   tt    [[     ]] nn nnn  yy   yy
#   tttt  [[     ]] nnn  nn yy   yy
#   tt    [[     ]] nn   nn  yyyyyy
#    tttt [[[[ ]]]] nn   nn      yy
#                            yyyyy
ident = DismalTony::UserIdentity.new
ident['first_name'] = 'Justin'
ident['last_name'] = 'Piotroski'
ident['nickname'] = 'Justin'


tony = DismalTony::VIBase.new
tony.load_handlers! "#{Dir.pwd}/lib/dismaltony/handlers"
# puts print tony.list_handlers
tony.query! 'say hello', ident
