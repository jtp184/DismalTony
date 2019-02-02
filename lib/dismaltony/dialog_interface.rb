require 'twilio-ruby'
require 'net/http'

module DismalTony # :nodoc:
  # The basic class for outputting message content to the user.
  class DialogInterface
    # The default formatting options as a hash
    def default_format
      {}
    end

    # Used to send the content of +_msg+ to the user via this interface.
    # Must be overriden by child classes.
    def send(_msg)
      raise 'Should be overriden by child classes'
    end
  end

  # Used for when no output is desired.
  class NowhereInterface < DialogInterface
    # Simply eats the message
    def send(_msg); end
  end

  # An Interface for outputting to the console. Basically just a <tt>puts</tt> command with more steps.
  class ConsoleInterface < DialogInterface
    # Sends +msg+ by calling <tt>puts</tt> on it.
    def send(msg)
      puts msg
    end

    def default_format
      { extra_space: true }
    end
  end

  # Used to facilitate Twilio SMS communication
  class SMSInterface < DialogInterface
    # The destination phone number. Format as <tt>/\+\d{10}/</tt>
    attr_reader :destination

    # Using +dest+ as its #destination, instanciates this Interface. Uses ENV vars for <tt>twilio_account_sid, twilio_auth_token</tt>
    def initialize(dest = nil)
      twilio_account_sid = ENV['twilio_account_sid']
      twilio_auth_token = ENV['twilio_auth_token']
      @client = Twilio::REST::Client.new twilio_account_sid, twilio_auth_token
      @destination = dest
    end

    # Sends the message +msg+ to #destination, with a quick check to see if it's empty. Uses ENV var for <tt>twilio_phone_number</tt>
    def send(msg)
      return nil if msg =~ /^ *$/
      raise 'No Destination!' if @destination.nil?

      if msg.chars.length < 1600
        @client.api.account.messages.create(
          from: ENV['twilio_phone_number'],
          to: destination,
          body: msg
        )
      else
        count_it = (msg.chars.length / 1600) + 1
        si = 0
        ei = 1600

        count_it.times do
          @client.api.account.messages.create(
            from: ENV['twilio_phone_number'],
            to: destination,
            body: msg[si..ei]
          )
          si += 1600
          ei += 1600
        end

     end
   end

    # Overrides the stored +destination+ and sends +msg+ to the number +num+ instead
    def send_to(msg, num)
      return nil if msg =~ /^ *$/

      @client.api.account.messages.create(
        from: ENV['twilio_phone_number'],
        to: num,
        body: msg
      )
    end
  end

  # Used for outputting to speech using the <tt>`say`</tt> command under MacOS
  class MacSpeechInterface < DialogInterface
    # Calls <tt>`say`</tt> on the message.
    # If the message is formatted, it prefaces +msg+ with the name of the emote
    def send(msg)
      if DismalTony::Formatter::OUTGOING.match?(msg)
        md = DismalTony::Formatter::OUTGOING.match msg
        emote = md['moji']
        text = md['message']
        `say #{DismalTony::EmojiDictionary.name(emote)}. #{text}`
      else
        `say #{msg}`
      end
    end
  end
end
