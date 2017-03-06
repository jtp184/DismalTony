require 'psych'

module DismalTony
	class DataStorage
		attr_accessor :opts
		attr_accessor :users

		def initialize(**args)
			if @opts.nil?
				@opts = args
			else
				@opts.merge! args
			end
			@users = []
		end

		def new_user(opts = {})
			noob = DismalTony::UserIdentity.new(:user_data => opts)
			@users << noob
			return noob
		end

		def on_query(_handled); end

		def find(&block)
			@users.select(&block)
		end

		def delete_user(user)
			@users.reject! {|u| u == user}
		end
	end
	class LocalStore < DataStorage
		def self.load_from(fp = '/')
			the_store = LocalStore.new(:filepath => fp)
			the_store.load
			return the_store
		end

		def self.create(fp = '/')
			the_store = LocalStore.new(:filepath => fp)
			the_store.save
			return the_store
		end

		def new_user(opts = {})
			noob = DismalTony::UserIdentity.new(:user_data => opts)
			@users << noob
			return noob
		end

		def on_query(handled)
			save
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
				new_env = enchilada['globals']['env_vars'].merge!(ENV.to_h)
				new_env.each_pair { |k, v| ENV[k] = v}
				@users += (enchilada['users'])
				@opts.merge!(enchilada['config']) do |k, o, n|
					if k == :filepath
						o
					else
						n
					end
				end
				return true
			rescue Exception => e
				return false
			end
		end

		def save
			output = {'users' => @users, 'globals' => {'env_vars' => ENV.to_h, 'config' => @opts}}
			begin
				File.open(@opts[:filepath],'w+') do |f|
					f << Psych.dump(output)
				end
				return true
			rescue Exception => e
				return false
			end
		end
	end
end