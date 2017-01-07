require 'twilio-ruby'
require 'tony/dialoginterface'

module Tony
class SMSInterface < DialogInterface
	attr_accessor :client
	attr_accessor :destination
	
	def initialize(dest = "")
		twilio_account_sid = 'AC6188347d1562eb480eec4771f7628f9a'
		twilio_auth_token = '7b56edc33f1e667929607257056b37eb'
		@client = Twilio::REST::Client.new twilio_account_sid, twilio_auth_token 
		@destination = dest
	end

	def send msg
		@client.account.messages.create(
			from: '+13476258669',
			to: self.destination,
			body: msg
			)
	end
end
end