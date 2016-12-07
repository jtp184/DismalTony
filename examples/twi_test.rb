require 'twilio-ruby'

# put your own credentials here
account_sid = 'AC6188347d1562eb480eec4771f7628f9a'
auth_token = '7b56edc33f1e667929607257056b37eb'

# set up a client to talk to the Twilio REST API
@client = Twilio::REST::Client.new account_sid, auth_token 

@client.account.messages.create(
  from: '+13476258669',
  to: '+18186208290',
  body: 'Twilio Test'
)
