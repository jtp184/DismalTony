require 'psych'

module DismalTony
	class DataStorage
		attr_accessor :opts
		attr_accessor :users

		def initialize(**opts); end

		def self.load; end

		def new_user; end

		def find; end

		def save_user(_user); end

		def delete_user(_user); end

		def self.configure(new_opts)
		end
	end
	class LocalStore < DataStorage
		@@global_opts = {}

		def self.define(**args)
			@@global_opts.merge! args
		end

		def self.global
			LocalStore.new(@@global_opts)
		end

		def initialize(**args)
			if @opts.nil?
				@opts = args
			else
				@opts.merge! args
			end
			@users = []
		end

		def load
			begin
				enchilada = Psych.load File.open(@opts[:filepath])
				enchilada['globals']['env_vars'].each_pair { |key, val| ENV[key] = val}
				@users += (enchilada['users'])
				@opts[:config] = enchilada['config']
			rescue Exception => e
				puts e.inspect
			end
		end

		def save
			output = {'users' => @users, 'globals' => {'env_vars' => ENV.to_h, 'config' => @config}}
			File.open(@opts[:filepath],'w+') do |f|
				f << Psych.dump(output)
			end
			return true
		end
	end

end