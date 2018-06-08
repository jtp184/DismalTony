require 'psych'
require 'redis'

module DismalTony # :nodoc:
  class RedisStore
    require 'redis'

    attr_reader :redis_options

    def initialize(opts = {})
      @redis_options = opts.fetch(:redis_options) { {} }
      @redis_client = Redis.new(redis_options)
      @identifier = opts.fetch(:identifier) { 'dismaltony' }
    end

    def new_user(opts = {})
      u_ident = DismalTony::UserIdentity.new(user_data: opts)
      @redis_client.set("#{@identifier}:users:", Psych.dump(u_ident))
    end

    def on_query; end

    def select_user(&block); end

    def delete_user(user); end

    def store_data(slug); end
  end
end
