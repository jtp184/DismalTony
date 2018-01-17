require 'dismaltony/version'
require 'dismaltony/directive'
require 'dismaltony/query'
require 'dismaltony/query_resolver'
require 'dismaltony/formatter'
require 'dismaltony/emoji_dictionary'
require 'dismaltony/handled_response'
require 'dismaltony/conversation_state'
require 'dismaltony/dialog_interface'
require 'dismaltony/user_identity'
require 'dismaltony/data_storage'
require 'dismaltony/scheduler'
require 'dismaltony/vi_base'

module DismalTony

	class NoDirectiveError < StandardError; end

	@@config = {
		data_store: nil,
		vi: nil,
	}

	def self.configure(&blk)
		yield @@config
		@@config
	end

	def self.config
		@@config
	end

	def self.vi
		return config[:vi] if config[:vi]
		data_store = if config[:data_store]
			config[:data_store]
		else
			nil
		end

		@@config[:vi] = DismalTony::VIBase.new(
			data_store: (config[:data_store])
			)
	end

	def self.vi=(vi)
		raise TypeError, "Not a VIBase!" unless vi.is_a? DismalTony::VIBase
		config[:vi] = vi
	end

	def self.call(*args)
		return vi if args.empty?
		return vi.(args[0]) if args.length == 1
		raise NoMethodError
	end
end