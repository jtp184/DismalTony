require 'twilio-ruby'
require 'sinatra'

post '/sms' do
  from_string = "FROM: #{params['From']}"
  message_string = "MSG: #{params['Body']}"

  puts 7.chr
  puts from_string
  puts message_string

  `ruby #{Dir.pwd}/TonyQuery.rb tel:#{params['From']} #{params['Body']}`
end