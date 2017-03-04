Dir.chdir("..")

require 'bundler'
Bundler.require(:development, :default)

#   tt    [[[[ ]]]]
#   tt    [[     ]] nn nnn  yy   yy
#   tttt  [[     ]] nnn  nn yy   yy
#   tt    [[     ]] nn   nn  yyyyyy
#    tttt [[[[ ]]]] nn   nn      yy
#                            yyyyy
@laptop_emoji = DismalTony::EmojiDictionary['laptop']
@ident = DismalTony::UserIdentity.new
# @ident['first_name'] = 'Justin'
# @ident['last_name'] = 'Piotroski'
# @ident['nickname'] = 'Justin'

@tony = DismalTony::VIBase.new
@tony.load_handlers! "#{Dir.pwd}/lib/dismaltony/handlers"
# @tony.load_handlers! "/Users/justinpiotroski/Documents/Work/Code/Ruby/dismaltony/dev-files/MultiTest/handlers"

def qp(str, debug = false)
	puts "[#{@laptop_emoji}]: #{str}"
	puts " #{@ident.conversation_state.inspect}" if debug
	@tony.query! str, @ident
	print " #{@ident.conversation_state.inspect}" if debug
	puts
end

# qp "setup", true
# qp "Justin", true
qp "hello", true

# 10.times{
#   print "[ #{@laptop_emoji}  ]: "
#   qp gets
# }
# qp 'Send a text'
# qp '8454890371'
# qp 'Hello!'

# qp 'roll a d20' 
