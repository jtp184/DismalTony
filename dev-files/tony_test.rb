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

# @db = DismalTony::LocalStore.create('/.code/Ruby/dismaltony/store.yml')
# @db.users << DismalTony::UserIdentity.new(
# 	:user_data => {"nickname" => 'Justin'}
# 	)
@db = DismalTony::LocalStore.new(
	:filepath => '/.code/Ruby/dismaltony/store.yml'
	)
@db.load
puts print @db.users

DismalTony::HandlerRegistry.load_handlers! "#{Dir.pwd}/lib/dismaltony/handlers"
@tony = DismalTony::VIBase.new(:data_store => @db)
puts print @db.inspect
# @tony.load_handlers! "/Users/justinpiotroski/Documents/Work/Code/Ruby/dismaltony/dev-files/MultiTest/handlers"

def qp(str, debug = false)
	puts "[#{@laptop_emoji}]: #{str}"
	puts " #{@db.users.first.conversation_state.inspect}" if debug
	@tony.query! str, @db.users.first
	print " #{@db.users.first.conversation_state.inspect}" if debug
	puts
end


qp "Roll a dice", true
qp "10", true

@db.save