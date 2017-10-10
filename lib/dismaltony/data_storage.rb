require 'psych' # :nodoc:

module DismalTony # :nodoc:
  # Represents the collection of options and users that comprise the VI's memory.
  # The base DataStore class is a non-persistent Data Store that functions fine in IRB
  # or for ephemeral instances, but doesn't save anything.
  # If you don't specify a data store to use, this is the default.
  class DataStore
    # A Hash that stores any configuration options
    attr_accessor :opts
    # an Array of UserIdentity objects that make up the userspace.
    attr_reader :users

    # Initializes an empty store, and merges +args+ with #opts
    def initialize(**args)
      @opts = {}
      @opts.merge!(args) unless args.nil?
      @users = []
    end

    # Creates a new UserIdentity object with UserIdentity.user_data set to +opts+
    # and then stores it in the #users array before returning it
    def new_user(opts = {})
      noob = DismalTony::UserIdentity.new(user_data: opts)
      @users << noob
      noob
    end

    # A kickback method. This method is called on VIBase#data_store at the end of VIBase#query!
    # to perform cleanup tasks like updating users or saving data, and is passed the HandledResponse via +_handled+
    def on_query(_handled); end

    # Syntactic sugar. Selects users for whom +block+ returns true
    def select(&block)
      @users.select(&block)
    end

    # Calls <tt>#reject!</tt> on +user+
    def delete_user(user)
      @users.delete(user)
    end
  end

  class YAMLStore
    attr_reader :filepath
    attr_reader :data_store

    def initialize(**args)
      @filepath = args[:filepath]
      @data_store = args[:data_store] || DataStore.new
    end

    def self.load_from(fp = './')
      loaded = self.new(filepath: fp, data_store: Psych.load(File.read(fp)))
      loaded.opts[:env_vars].each_pair { |key, val| ENV[key] = val }
      loaded
    end

    def self.create_at(fp)
      new_store = self.new(filepath: fp)
      new_store.save
    end

    def on_query(_handled)
      save
    end

    def save
      File.open(filepath, 'w+') { |f| f << Psych.dump(data_store) }
      self
    end

    def method_missing(name, *params)
      @data_store.respond_to?(name) ? @data_store.method(name).(*params) : super
    end
  end
end
