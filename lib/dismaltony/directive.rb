module DismalTony # :nodoc:
  # Respresents a response to an incoming query. 
  # Handles providing match conditions as well as what to do when matched
  # TODO: Separated Mixins that simplify common functions
  
  class Directive
    attr_reader :group
    attr_reader :name
    attr_reader :query

    class << self
      attr_reader :name #:nodoc:
    end

    class << self
      attr_reader :group #:nodoc:
    end

    def initialize
    end

  end
end