require 'psych' # :nodoc:
require 'redis' # :nodoc:

module DismalTony # :nodoc:
  # Represents the collection of options and users that comprise the VI's memory.
  # The base DataStore class is a non-persistent Data Store that functions fine in IRB
  # or for ephemeral instances, but doesn't save anything.
  # If you don't specify a data store to use, this is the default.
  class DataStore
    # A Hash that stores any configuration options
    attr_reader :opts
    # an Array of UserIdentity objects that make up the userspace.
    attr_reader :users
    # A Hash that stores settings and records for directives
    attr_reader :directive_data

    # Initializes an empty store, and extracts data from +args+
    def initialize(args={})
      @opts = {}
      @opts.merge!(args.fetch(:opts) { {} })
      @users = args.fetch(:users) { [] }
      @directive_data = args.fetch(:directive_data) { Hash.new({}) }
    end

    # Creates a new UserIdentity object with UserIdentity.user_data set to +opts+
    # and then stores it in the #users array before returning it
    def new_user(opts = {})
      noob = DismalTony::UserIdentity.new(user_data: opts)
      @users << noob
      noob
    end

    # A kickback method. This method is called on VIBase#data_store at the end of VIBase#query!
    # to perform cleanup tasks like updating users or saving data, and is passed values for the
    # HandledResponse +_response+, UserIdentity +_user+, and the +_data+ representation of the result
    # if available.
    def on_query(*args); end

    # Syntactic sugar. Selects users for whom +block+ returns true
    def select_user(&block)
      @users.select(&block)
    end

    # Calls <tt>#reject!</tt> on +user+
    def delete_user(user)
      @users.delete(user)
    end

    # Uses the hash +slug+ to insert a new value into the #directive_data hash
    def store_data(slug)
      dr, ky, vl = slug.fetch(:directive), slug.fetch(:key), slug.fetch(:value)
      @directive_data[dr] ||= {}
      @directive_data[dr][ky] = vl
    rescue KeyError
      nil
    end

    # Using the directive's +dname+ and the nested keys 
    # +ky+, digs inside +directive_data+ for the information
    def read_data(dname, *ky)
      directive_data.dig(dname, *ky)
    end

    def set_opt(k, v)
      @opts[k] = v
    end

    def load_opts
      @opts
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
    def initialize(args={})
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
    def on_query(*_args)
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

  class RedisStore
    attr_reader :opts

    def initialize(args={})
      @redis = Redis.new(args.fetch(:redis_config) { {} })
      load_opts
    end

    def new_user(args = {})
      tu = DismalTony::UserIdentity.new(user_data: args)
      commit_user(serialize_out(tu))
      tu
    end

    def on_query(**args)
      user = args.fetch(:user)
      response = args.fetch(:response)
      commit_user(serialize_out(user))
      user = select_user(user[:uuid])
    end

    def select_user(uid=nil,&block)
      if uid.nil? && block_given?
        all_users.select(&block)
      elsif !uid.nil?
        serialize_in(@redis.hgetall(user_key({uuid: uid})))
      else
        nil
      end
    end

    def update_user(uid,&block)
      u = select_user(uid)
      yield u
      commit_user(serialize_out(u))
      u
    end

    def delete_user(user)
      ukey = user_key(user)
      to_delete = @redis.hgetall(ukey).keys
      @redis.pipelined { to_delete.each { |j| @redis.hdel(ukey, j) } }
      user
    end

    def all_users
      allofem = @redis.keys("DismalTony:UserIdentity:*")
      @redis.pipelined { allofem.map! { |a| @redis.hgetall(a) } }
      allofem.map!(&:value)
      allofem.map! { |a| serialize_in(a) }
      allofem
    end

    def users
      all_users
    end

    def directive_data
      {}
    end

    def store_data(slug)
      dr, ky, vl = slug.fetch(:directive).to_s, slug.fetch(:key).to_s, Psych.dump(slug.fetch(:value))
      @redis.hset directive_key(dr), ky, vl
    rescue KeyError
      nil
    end

    def read_data(dname, *ky)
      initial = ky.shift
      s = Psych.load(@redis.hget directive_key(dname), initial)
      return s if ky.empty?
      s.dig(*ky)
    end

    def set_opt(k, v)
      @redis.hset("DismalTony:RedisStore:opts", k.to_s, Psych.dump(v))
      load_opts
    end

    def load_opts
      o = @redis.hgetall("DismalTony:RedisStore:opts").clone
      o.transform_keys!(&:to_sym)
      o.transform_values! { |v| Psych.load(v) }
      o[:env_vars]&.each_pair { |key, val| ENV[key.to_s] = val }
      @opts = o
    end

    private

    def commit_user(fields)
      zipper = fields.to_a.flatten
      @redis.hmset user_key(fields), *zipper
    end

    def serialize_out(model)
      hfields = {}
      puts hfields.inspect
      hfields['conversation_state'] = Psych.dump(model.conversation_state)
      puts hfields.inspect
      model.user_data.each do |hkey, hval|
        hfields[hkey.to_s] = Psych.dump(hval)
      end
      hfields['uuid'] = Psych.load(hfields['uuid'])
      puts hfields.inspect
      hfields
    end

    def serialize_in(redis_hash)
      h = redis_hash.clone
      puts h.inspect
      h.transform_keys!(&:to_sym)
      puts h.inspect
      h.transform_values! { |v| Psych.load v }
      puts h.inspect
      cs = h.delete(:conversation_state)
      puts cs.inspect
      DismalTony::UserIdentity.new(user_data: h, conversation_state: cs)
    end

    def directive_key(dk)
      "DismalTony:#{dk}"
    end

    def user_key(either)
      "DismalTony:UserIdentity:#{either[:uuid]}"
    end
  end
end
