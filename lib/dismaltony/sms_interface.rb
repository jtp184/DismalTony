require 'twilio-ruby'
module DismalTony
  class SMSInterface < DialogInterface
    attr_accessor :client
    attr_accessor :destination

    def initialize(dest = '')
      twilio_account_sid = ENV['twilio_account_sid']
      twilio_auth_token = ENV['twilio_auth_token']
      @client = Twilio::REST::Client.new twilio_account_sid, twilio_auth_token
      @destination = dest
    end

    def send(msg)
      unless msg =~ /^\s+$/
      @client.account.messages.create(
        from: '+13476258669',
        to: destination,
        body: msg
      )
      end
    end
  end
end
