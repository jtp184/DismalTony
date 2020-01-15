module DismalTony # :nodoc:
  module DirectiveHelpers # :nodoc:
  	# Assists in asking questions of the user, and setting fragments based on them
  	module InterrogativeHelpers
  		include HelperTemplate

      # A Struct for handling the ask / user input cycle
  		Interrogative = Struct.new(:fragment, :message, :parse_next, :original, :after_cast) do
  			def been_cast?
  				after_cast
  			end

  			def value
  				after_cast ? after_cast : original
  			end
  		end

  		# Contains the Class methods of the helper, which are added on inclusion
  		module ClassMethods
  		end

  		# Contains the instance methods of the helper, which are added on inclusion
  		module InstanceMethods
        # Takes in +args+ for :fragment and :message,
        # and optionally :parse_next and :cast
  			def ask_for(args={})
  				target_frag = args.fetch(:fragment)

  				interrogative_fragments << target_frag
  				interrogative_asking_procs[target_frag] = args.fetch(:cast, :itself.to_proc)

  				frag = fragments.fetch(target_frag, false)
				  
  				known = if frag && frag.been_cast?
				  					fragments[target_frag]
				  				elsif frag && frag.original
				  					cast_proc = interrogative_asking_procs[target_frag]
				  					
				  					fragments[target_frag].after_cast = cast_proc.(fragments[target_frag].original)
				  					
				  					fragments[target_frag]
				  				else
				  					false
				  				end

				  return known if known

				  fragments[target_frag] ||= Interrogative.new(target_frag)
  				fragments[target_frag].message = args.fetch(:message)
  				fragments[target_frag].parse_next = args.fetch(:parse_next, true)

  				fragments[target_frag]
  			end

        # Takes in +args+ for :fragment and optionally :method.
        # Sets the fragment to a new Interrogative and then passes control flow
        # to the method
  			def user_input_for(args={})
  				target_frag = args.fetch(:fragment)

  				fragments[target_frag] ||= Interrogative.new

  				fragments[target_frag].fragment ||= target_frag
  				fragments[target_frag].original = query.raw_text
  				
  				self.send(args.fetch(:method, :run))
  			end

        # Gets all fragments that were defined with ask_for, 
        # casts the ones who have not been cast but can be and returns 
        # either a HandledResponse asking for the user input or nil
  			def ask_frags
  				sub_f = fragments.slice(*interrogative_fragments.to_a).values

  				filled, unfilled = sub_f.partition { |f| f.value ? true : false }
  				cast, uncast = sub_f.partition(&:been_cast?)

  				castable = filled & uncast

          castable.each do |c|
            c.after_cast = interrogative_asking_procs[c.fragment].(c.original)
          end

  				filled, unfilled = sub_f.partition { |f| f.value ? true : false }
  				cast, uncast = sub_f.partition(&:been_cast?)

  				return nil unless uncast.any?

          single = uncast.sort_by { |f| f.fragment }.first

  				DismalTony::HandledResponse.then_do(
            message: single.message,
            directive: self,
            method: :"user_input_for_#{single.fragment}",
            parse_next: single.parse_next,
            data: fragments
  				)
  			end

        # Stores all interrogative fragments in a set for uniqueness operations
  			def interrogative_fragments
  				@interrogative_fragments ||= Set.new
  			end

        # A hash to store casting procs for interrogatives
  			def interrogative_asking_procs
  				@interrogative_asking_procs ||= {}
  			end

        # Defined such that any ask_for_* or user_input_for_* method works
  			def method_missing(mtd, *args)
  				super unless [/^ask_for/, /^user_input_for/].any? { |sig| mtd.to_s =~ sig }

  				prams = args.first ? args.first.to_hash : {}

  				case mtd.to_s
  				when /^ask_for/
  					ask_for({fragment: mtd.to_s.match(/^ask_for_(.*)/)[1].to_sym}.merge(prams))
  				when /^user_input_for/
  					user_input_for({fragment: mtd.to_s.match(/^user_input_for_(.*)/)[1].to_sym}.merge(prams))
  				end
  			end
  		end
  	end
  end
end