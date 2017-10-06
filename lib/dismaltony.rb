require 'dismaltony/version'
require 'dismaltony/directive'
require 'dismaltony/query'
require 'dismaltony/formatter'
require 'dismaltony/dialog_interface'
require 'dismaltony/emoji_dictionary'
require 'dismaltony/conversation_state'
require 'dismaltony/user_identity'
require 'dismaltony/data_storage'
require 'dismaltony/handled_response'
require 'dismaltony/query_handler'
require 'dismaltony/handler_registry'
require 'dismaltony/scheduler'
require 'dismaltony/vi_base'

module DismalTony
  # Defines a new Handler and registers it in the HandlerRegistry
  #
  # * +sc+ - The subclass of QueryHandler to use.
  # * +block+ - The code block to use as the class's evaluation.
  def self.create_handler(sc = DismalTony::QueryHandler, &block)
    c = Class.new(sc, &block)
    DismalTony::HandlerRegistry.register(c)
  end
end
#
