require 'google_maps_service'

module DismalTony::DirectiveHelpers
	module GoogleMapsServiceHelpers
		include HelperTemplate

		module ClassMethods
			def gmaps_client
				@gmaps_client ||= GoogleMapsService::Client.new(key: ENV['google_maps_api_key'])
			end

			def data_struct_template
				@data_struct_template ||= Struct.new('GoogleMapsRoute', :distance, :duration, :start_address, :end_address, :steps, :raw) do
					def step_list
						outp = ""
						steps.each_with_index do |slug, ix|
							outp << "#{ix+1}) " << slug[:html_instructions].gsub(/<([A-Z][A-Z0-9]*)\b[^>]*>(.*?)<\/\1/i) { $2 } << "\n"
						end
						outp
					end

					def step_string(n)
						steps[n][:html_instructions].gsub(/<([A-Z][A-Z0-9]*)\b[^>]*>(.*?)<\/\1/i) { $2 }
					end
				end
			end

		end

		module InstanceMethods
			def gmaps_client
				@gmaps_client ||= self.class.gmaps_client
				@gmaps_client
			end

			def gmaps_directions(opts={})
				req = gmaps_client.directions(
					opts.fetch(:start_address),
					opts.fetch(:end_address),
					mode: opts.fetch(:mode) { 'driving' },
					alternatives: false
					)
				legs = req[:legs]

				ds_args = []

				ds_args << Unit.new("#{legs[:distance][:value]}m")
				ds_args << Duration.new(second: legs[:duration][:value])
				ds_args << legs[:start_address]
				ds_args << legs[:end_address]
				ds_args << legs[:steps]
				ds_args < req

				data_struct_template.new(*ds_args)
			end
		end
	end
end

module DismalTony::Directives
	class TrafficReportDirective < DismalTony::Directive
		include DismalTony::DirectiveHelpers::CoreHelpers
		include DismalTony::DirectiveHelpers::DataRepresentationHelpers
		include DismalTony::DirectiveHelpers::DataStructHelpers
		include DismalTony::DirectiveHelpers::ConversationHelpers
		include DismalTony::DirectiveHelpers::EmojiHelpers
		include DismalTony::DirectiveHelpers::GoogleMapsServiceHelpers

		PATIENCE_LIMITS = {
			:none => Duration.new(minutes: 10).freeze,
			:low => Duration.new(minutes: 30).freeze,
			:medium => Duration.new(minutes: 50 ).freeze,
			:high => Duration.new(minutes: 90).freeze,
			:very_high => Duration.new(hours: 2).freeze,
		}

		set_name :traffic_report
		set_group :info

		add_param :gmaps_data
		add_param :start_address
		add_param :end_address
		add_param :info_type
		add_param :step_index, 0

		add_criteria do |qry|
			qry << keyword { |q| q.contains?(/directions/i, /traffic/i, /long/i, /far/i, /navigate/i) }
			qry << could { |q| q.contains?(/^from$/i, /^to$/i, /^between$/i) }
			qry << could { |q| q =~ /how do i get/i }
		end

		def run
    	asking_for = {}

    	asking_for[:traffic_time] = query.contains?(/^time$/i, /^bad$/i, /^time$/i, /^long$/i)
    	asking_for[:distance] = query.contains?(/^distance$/i, /^far$/i, /^between$/i)
    	asking_for[:directions] = query =~ /give me/i || query.contains?(/^directions$/i)
  		asking_for[:step_by_step] = query =~ /how do i get to/i || query.contains?(/navigate/i)

  		parameters[:info_type] = asking_for.find { |k, v| v }

  		c = case parameters[:info_type]
  		when :distance
  			conf = check_for_start_and_end(false, true)
  			return conf if conf
  			nil
  		when :directions
  			conf = check_for_start_and_end(false, true)
  			return conf if conf
  			nil
  		when :step_by_step
  			conf = check_for_start_and_end
  			return conf if conf
  			nil
  		when :traffic_time
  			conf = check_for_start_and_end(false, true)
  			return conf if conf
  			nil
  		else
  			nil
  		end

  		return c if c

  		resp, data_rep = choose_response
  		return_data(data_rep)
  		resp
  	end

  	private

  	def check_for_start_and_end(care_about_start=true, care_about_end=true)
  		e = if parameters[:end_address].nil? && query =~ /to (.*)/i
  			parameters[:end_address] = $1
  			parameters[:end_address] = check_shortcut parameters[:end_address]
  			nil
  		else
  			DismalTony::HandledResponse.then_do(message: "~e:worldmap What is the end address of the route?", directive: self, method: receive_end_address, data: parameters, parse_next: false)
  		end

  		s = if parameters[:start_address].nil? && query =~ /(?:from|between) (.*)/i
  			parameters[:start_address] = $1
  			parameters[:start_address] = check_shortcut parameters[:start_address]
  			nil
  		else
  			DismalTony::HandledResponse.then_do(message: "~e:mappin What is the start address of the route?", directive: self, method: receive_start_address, data: parameters, parse_next: false)
  		end

  		return e if e && care_about_end
  		return s if s && care_about_start
  		nil
  	end

  	def receive_start_address
  		parameters[:start_address] = query.raw_text
  		DismalTony::HandledResponse.then_do(message: "~e:worldmap What is the end address of the route?", directive: self, method: receive_end_address, data: parameters, parse_next: false)
  	end

  	def receive_end_address
  		parameters[:end_address] = query.raw_text

  		resp, data_rep = choose_response
  		return_data(data_rep)
  		resp
  	end

  	def choose_response
  		case parameters[:info_type]
  		when :traffic_time
  			list_all_directions
  		when :distance
  			get_distance
  		when :directions
  			list_all_directions
  		when :step_by_step
  			page_directions
  		end
  	end

  	def list_all_directions
  		say_this = ""
  		say_this << "~e:#{random_emoji('mappin', 'worldmap', 'car', 'bus', 'globe')} "
  		say_this << "Okay! I'll list the directions for you."
  		say_this << "\n\n"
  		say_this << get_gmaps_data.step_list
  		return get_gmaps_data, DismalTony::HandledResponse.finish(say_this)
  	end

  	def page_directions
  	end

  	def get_traffic_time
  		req = get_gmaps_data
  		t = req.duration

  		badness = PATIENCE_LIMITS.find do |k, v|
  			t < v
  		end.first

  		moji_choice = case badness
  		when :none
  			random_emoji('100', 'star', 'thumbsup', 'car', 'clock', 'stopwatch')
  		when :low
  			random_emoji('clock', 'stopwatch', 'mappin', 'worldmap', 'car')	
  		when :medium
  			random_emoji('stopwatch', 'hourglass', 'alarmclock', 'worldmap', 'car', 'bus', '')
  		when :high
  			random_emoji('frown', 'gate', 'car', 'hourglass', 'alarmclock', 'snail')
  		when :very_high
  			random_emoji('bomb', 'gate', 'car', 'hourglass', 'snail', 'frown', 'pickaxe')
  		else
  			time_emoji
  		end

  		badness_string = case badness
  		when :none
  			["very light", "quite low", "very low", "pretty good"].sample
  		when :low
  			["low", "not bad", "light"].sample
  		when :medium
  			["okay", "not too bad", "fine", "decent"].sample
  		when :high
  			["somewhat heavy", "a bit dense", "a bit clogged", "heavy", "high", "dense"].sample
  		when :very_high
  			["backed up", "very heavy", "very high", "highly dense", "significant"].sample
  		else	
  			'harrowing'
  		end

  		say_this = ""
  		say_this << "~e:#{moji_choice} "
  		say_this << "The traffic on the way to #{parameters[:end_address]} is #{badness_string}. It will take #{t.format("%h %~h and %m %~m")} to get there."
  		return get_gmaps_data, DismalTony::HandledResponse.finish(say_this)
  	end

  	def get_distance
  		req = get_gmaps_data

  		say_this = ""
  		say_this << "~e:#{moji_choice} "
  		say_this << "#{parameters[:end_address]} is #{d.convert('mi').round(2).to_f.to_s}mi away from #{parameters[:start_address]}."
  		return get_gmaps_data, DismalTony::HandledResponse.finish(say_this)
  	end

  	def check_shortcut(addr='')
  		srch = vi.user[(addr.gsub(/\.\?\,\!\'/i, '') + '_address').to_sym]
  		if srch
  			srch
  		else
  			addr
  		end
  	end

  	def get_gmaps_data
  		parameters[:gmaps_data] ||= gmaps_directions(start_address: parameters[:start_address], end_address: parameters[:end_address])
  	end
  end
  
  # class RememberLocationDirective < DismalTony::Directive
  # 	include DismalTony::DirectiveHelpers::DataRepresentationHelpers
  # 	include DismalTony::DirectiveHelpers::DataStructHelpers
  # 	include DismalTony::DirectiveHelpers::GoogleMapsServiceHelpers
  # 	include DismalTony::DirectiveHelpers::ConversationHelpers
  # 	include DismalTony::DirectiveHelpers::EmojiHelpers
  # end
end