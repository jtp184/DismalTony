require 'dismaltony/version'
require 'dismaltony/match_logic'
require 'dismaltony/query'
require 'dismaltony/directive_helpers/directive_helpers'
require 'dismaltony/directive'
require 'dismaltony/query_resolver'
require 'dismaltony/formatter'
require 'dismaltony/handled_response'
require 'dismaltony/conversation_state'
require 'dismaltony/dialog_interface'
require 'dismaltony/user_identity'
require 'dismaltony/data_store'
require 'dismaltony/vi_base'

# A Conversational Agent for task performance.
module DismalTony
  # Used when no Directive is found to satisfy the query
  class NoDirectiveError < StandardError; end
  # Signfies a failure of a MatchLogic object to match on a Query
  class MatchLogicFailure < StandardError; end

  # The hash of configuration data, including the default DataStore and VIBase
  @@config = {
    data_store: nil,
    vi: nil
  }

  # Yields the +config+ varable to the block +blk+ so you can define settings.
  def self.configure # :yields: config
    yield @@config
    @@config
  end

  # Retrieves the stored result of the last Directive evaluated
  def self.last_result
    @last_result
  end

  # Stores the result of the last Directive evaluated
  def self.last_result=(new_one)
    @last_result = new_one
  end

  # Returns the configuration hash
  def self.config
    @@config
  end

  # Returns the VIBase in the config. Creates a basic one if none exists.
  def self.vi
    return config[:vi] if config[:vi]

    data_store = config[:data_store]

    @@config[:vi] = DismalTony::VIBase.new(
      data_store: config[:data_store]
    )
  end

  # Overrides the VI inside the config with the one passed in. Very strict about typing.
  def self.vi=(vi)
    raise TypeError, 'Not a VIBase!' unless vi.is_a? DismalTony::VIBase

    config[:vi] = vi
  end

  # The main point of interaction. If +args+ is empty, it returns the same as #vi,
  # but otherwise passes the single string arg on to VIBase#call
  def self.call(*args)
    return vi if args.empty?
    return vi.call(args[0]) if args.length == 1

    raise NoMethodError
  end
end
