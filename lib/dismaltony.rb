require 'dismaltony/version'
require 'dismaltony/formatter/formatter'
require 'dismaltony/dialog_interface'
require 'dismaltony/mac_speech_interface'
require 'dismaltony/console_interface'
require 'dismaltony/sms_interface'
require 'dismaltony/emoji_dictionary'
require 'dismaltony/conversation_state'
require 'dismaltony/user_identity'
require 'dismaltony/data_storage'
require 'dismaltony/handled_response'
require 'dismaltony/query_handler'
require 'dismaltony/handler_registry'
require 'dismaltony/vi_base'

module DismalTony
  def self.create_handler(sc = DismalTony::QueryHandler, &block)
  	c = Class.new(sc, &block)
  	DismalTony::HandlerRegistry.register(c)  	
  end
end
#
