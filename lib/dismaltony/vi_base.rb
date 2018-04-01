 module DismalTony # :nodoc:
  # The essential class. A VI, or Virtual Intelligence,
  # forms the basis for the DismalTony gem, and is your conversational agents for handling queries
  class VIBase
    # The name of the Intelligence
    attr_reader :name
    # A DialogInterface object representing where to route the VI's speech
    attr_reader :return_interface
    # An Array of QueryHandler objects that the VI can use
    attr_reader :directives
    # A DataStore object representing the VI's memory and userspace
    attr_reader :data_store
    # The UserIdentity corresponding to the current user.
    attr_reader :user
    # the Scheduler object for executing timed tasks
    attr_reader :scheduler

    # Options for +opts+
    # * +:name+ - The name for the VI. Defaults to 'Tony'
    # * +:directives+ - The Array of directives. Defaults to the entire contents of the HandlerRegistry.
    # * +:data_store+ - The data store to use with this VI. Defaults to a generic DataStore object.
    # * +:return_interface+ - The interface to route conversation back through. Defaults to the ConsoleInterface.
    # * +:user+ - the UserIdentity of who is using this VI
    def initialize(**opts)
      @name = (opts[:name].freeze || opts[:data_store]&.opts&.[](:vi_name) || 'Tony'.freeze)
      @return_interface = (opts[:return_interface] || DismalTony::ConsoleInterface.new)
      @directives = (opts[:directives] || DismalTony::Directives.all)
      if opts[:data_store]
        opts[:data_store].opts[:vi_name] = @name
        @data_store = opts[:data_store]
      else
        @data_store = DismalTony::DataStore.new(vi_name: name)
      end
      @user = (opts[:user] || @data_store&.users&.first || DismalTony::UserIdentity::DEFAULT)
    end

    # Takes the module level VI and duplicates it, overriding its values with ones from +opts+
    def self.inherit(**opts)
      DismalTony::VIBase.new(
        user: (opts[:user] || DismalTony.().user || DismalTony::UserIdentity::DEFAULT),
        name: (opts[:name] || DismalTony.().name),
        return_interface: (opts[:return_interface] || DismalTony.().return_interface),
        directives: (opts[:directives] || DismalTony.().directives),
        data_store: (opts[:data_store] || DismalTony.().data_store)
        )
    end

    # Sends the message +str+ back through the DialogInterface +interface+, after calling DismalTony::Formatter.format on it.
    def say_through(interface, str)
      interface.send(DismalTony::Formatter.format(str, interface.default_format))
    end

    # Sends the message +str+ back through the DialogInterface +interface+, after calling DismalTony::Formatter.format on it, with the options +opts+
    def say_opts(interface, str, opts)
      interface.send(DismalTony::Formatter.format(str, opts))
    end

    # Simplest dialog function. Sends the message +str+ back through VIBase.return_interface
    def say(str)
      return_interface.send(DismalTony::Formatter.format(str, return_interface.default_format))
    end

    # The interface method takes in a Query +q+ and uses the QueryResolver#call method to decide what to do with it.
    # Responsible for using the +return_interface+ to send back the text response.
    def call(q)
      result = QueryResolver.(q, self)
      response = result.response
      if response.format.empty?
        say response.outgoing_message
      else
        say_opts(return_interface, response.outgoing_message, return_interface.default_format.merge(response.format)) unless response.format[:silent]
      end
      data_store.on_query(response)
      @user.modify_state!(response.conversation_state.stamp)
      result      
    end
  end
end
