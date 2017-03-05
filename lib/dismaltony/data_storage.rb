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
			args.keys.each do |key|
				self.instance_variable_set("@#{key.to_s}", args[key])
			end
			@users = []
		end

		def load
			begin
				enchilada = Psych.load File.open(@@global_opts[:database_filepath])
				enchilada['envs'].each_pair { |key, val| ENV[key] = val}
				enchilada['users'].each do |payload|
					ud = payload['user_data']
					cs = payload['conversation_state']

					uid = DismalTony::UserIdentity.new(:user_data => ud)

					cs_1 = {}
					cs.keys.each do |key|
						cs_1[key.to_sym] = cs[key]
					end

					state = DismalTony::ConversationState.new.from_h!(cs_1)
					uid.conversation_state = state
					@users << uid
				end			
			rescue Exception => e
				ud = {'nickname' => 'User', 'Icon' => 'laptop'}
				uid = DismalTony::UserIdentity.new(:user_data => ud) 
				state = DismalTony::ConversationState.new(:user_identity => uid)
				uid.conversation_state = state
			end
		end

		def save
			output = {'users' => @users, 'globals' => {'env_vars' => ENV, 'config' => @config}}
			File.open('store.yml','w') do |f|
				f << Psych.dump(output)
			end
			return true
		end
	end

end