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
    def initialize(**args={}
      @opts = {}
      @opts.merge!(args.fetch(:opts) { {} })
      @users = args.fetch(:users) { [] }
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

  # Represents storing the DataStore to disk in a YAML file. A relatively simple wrapper around
  # the internal DataStore that handles loading and saving the YAML.
  class YAMLStore
    # The location of the store on disk
    attr_reader :filepath
    # The wrapped DataStore object
    attr_reader :data_store

    # Args takes hooks for :filepath and :data_store, and autopopulates them if not present.
    def initialize(**args)
      @filepath = args.fetch(:filepath) { "./tony.yml" }
      @data_store = args.fetch(:data_store) { DataStore.new }
    end

    # Takes a filepath +fp+ and reads in that YAMLStore.
    def self.load_from(fp = './tony.yml')
      loaded = self.new(filepath: fp, data_store: Psych.load(File.read(fp)))
      loaded.opts[:env_vars]&.each_pair { |key, val| ENV[key] = val }
      loaded
    end

    # Creates a new YAMLStore at the filepath +fp+, and saves it to disk as well.
    def self.create_at(fp)
      new_store = self.new(filepath: fp)
      new_store.save
    end

    # Kickback function. Ignores +_handled+ and saves to disk after every query.
    def on_query(_handled)
      save
    end

    # Overwrites the file at +filepath+ with the current data.
    def save
      File.open(filepath, 'w+') { |f| f << Psych.dump(data_store) }
      self
    end

    # Forcibly reloads the store
    def load
      load_from(filepath)
    end

    # Checks the internal +datastore+ to see if it responds to +name+, and passes the +params+ along.
    def method_missing(name, *params)
      @data_store.respond_to?(name) ? @data_store.method(name).(*params) : super
    end
  end
end
