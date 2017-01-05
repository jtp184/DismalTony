require 'twilio-ruby'
require 'sinatra'

post '/sms' do
  puts print params

  `ruby #{Dir.pwd}/TonyQuery.rb tel:#{params['From']} #{params['Body']}`
end