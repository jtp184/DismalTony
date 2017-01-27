require 'sinatra'
require_relative 'simple_database'
require 'bundler'
Bundler.require(:development, :default)

# get '/start' do
$database = SimpleDatabase.new
$database.add_table(:users)
# justin = DismalTony::UserIdentity.new
# justin['first_name'] = 'Justin'
# justin['phone_number'] = '+18186208290'

# $database.insert(:users, justin)

$tony = DismalTony::VIBase.new
$tony.load_handlers! "/Users/justinpiotroski/Documents/Work/Code/Ruby/dismaltony/dev-files/MultiTest/handlers"

# end

post '/sms' do
  puts print $database.get_table(:users)
  puts
  from_number = params['From']
  message_string = params['Body']

  $tony.return_interface = DismalTony::SMSInterface.new(from_number)

  whom = ($database.get_table(:users).keep_if { |u| u['phone_number'].eql? from_number}).first
  if whom
    puts "[#{whom['first_name']}]: #{message_string}"
    $tony.say_through(DismalTony::ConsoleInterface.new, ($tony.query!(message_string, whom)).to_s)
  else
    whom = DismalTony::UserIdentity.new
    whom['phone_number'] = from_number
    puts "[#{from_number}]: #{message_string}"
    $tony.say_through(DismalTony::ConsoleInterface.new, ($tony.query!(message_string, whom)).to_s)
    $database.insert(:users, whom)
  end
  puts
end

