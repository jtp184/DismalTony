require 'google_maps_service'
require 'ruby-units'
require 'duration'

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
            outp = ''
            steps.each_with_index do |_slug, ix|
              outp << "#{ix + 1}) " << step_string[ix] << "\n"
            end
            outp
          end

          def step_string(n)
            i = steps[n][:html_instructions].clone
            i.gsub!(/<div\b[^>]*>(.*?)<\/div>/i) { "\n" + Regexp.last_match(2) }
            i.gsub!(/<([A-Z][A-Z0-9]*)\b[^>]*>(.*?)<\/\1>/i) { Regexp.last_match(2) }
            i
          end
        end
      end
    end

    module InstanceMethods
      def gmaps_client
        @gmaps_client ||= self.class.gmaps_client
        @gmaps_client
      end

      def gmaps_directions(opts = {})
        req = gmaps_client.directions(
          opts.fetch(:start_address),
          opts.fetch(:end_address),
          mode: opts.fetch(:mode) { 'driving' },
          alternatives: false
        ).first
        legs = req[:legs].first

        ds_args = []

        ds_args << Unit.new("#{legs[:distance][:value]}m")
        ds_args << Duration.new(second: legs[:duration][:value])
        ds_args << legs[:start_address]
        ds_args << legs[:end_address]
        ds_args << legs[:steps]
        ds_args << req

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
      none: Duration.new(minutes: 10).freeze,
      low: Duration.new(minutes: 20).freeze,
      medium: Duration.new(minutes: 50).freeze,
      high: Duration.new(minutes: 90).freeze,
      very_high: Duration.new(hours: 2).freeze
    }.freeze

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

    add_synonyms do |make|
      make[/^none$/i] = ['very light', 'quite low', 'very low', 'pretty good']
      make[/^low$/i] = ['low', 'not bad', 'light']
      make[/^medium$/i] = ['okay', 'not too bad', 'fine', 'decent']
      make[/^high$/i] = ['somewhat heavy', 'a bit dense', 'a bit clogged', 'heavy', 'high', 'dense']
      make[/^very high$/i] = ['backed up', 'very heavy', 'very high', 'highly dense', 'significant']
    end

    def run
      x = determine_intent
      return x unless parameters[:info_type]

      check_for_start_and_end

      y = confirm_start_and_end
      confirmed = y.shift

      resp = if confirmed
               data_rep, r = choose_response

               return_data(data_rep)
               r
             else
               y.shift
      end

      resp
    end

    private

    def determine_intent
      asking_for = {}

      asking_for[:traffic_time] = query.contains?(/^time$/i, /^bad$/i, /^time$/i, /^long$/i, /^traffic$/i)
      asking_for[:directions] = query =~ /give me/i || query.contains?(/^directions$/i)
      asking_for[:step_by_step] = query =~ /how do i get to/i || query.contains?(/navigate/i)
      asking_for[:distance] = query.contains?(/^distance$/i, /^far$/i, /^between$/i)

      parameters[:info_type] = asking_for.find { |_k, v| v }.first

      if parameters[:info_type].nil?
        DismalTony::HandledResponse.finish("~e:frown I'm sorry, I couldn't figure out what maps function you wanted. Try talking about directions, traffic, or distance")
      else
        parameters[:info_type]
      end
    end

    def confirm_start_and_end
      unresolved = []

      if parameters[:start_address].nil?
        unresolved << false
        res = DismalTony::HandledResponse.then_do(message: '~e:mappin What is the start address of the route?', directive: self, method: receive_start_address, data: parameters, parse_next: false)
        unresolved << res
      end

      if parameters[:end_address].nil?
        unresolved << false if unresolved.empty?
        res = DismalTony::HandledResponse.then_do(message: '~e:worldmap What is the end address of the route?', directive: self, method: receive_end_address, data: parameters, parse_next: false)
        unresolved << res
      end

      if parameters[:start_address] && parameters[:end_address]
        unresolved << true
      end

      unresolved
    end

    def check_for_start_and_end
      m = query.to_str.match(/(?:from|between) (.*) (?:to|and) (.*)/i)
      s = m[1].gsub(/[\?\.\,\!]/, '')
      e = m[2].gsub(/[\?\.\,\!]/, '')

      s = check_shortcut(s) if s.count(' ') == 0
      e = check_shortcut(e) if e.count(' ') == 0

      parameters[:start_address] ||= s
      parameters[:end_address] ||= e
    end

    def receive_start_address
      parameters[:start_address] = query.raw_text
      confirm_start_and_end
    end

    def receive_end_address
      parameters[:end_address] = query.raw_text
      confirm_start_and_end
    end

    def choose_response
      x, y = case parameters[:info_type]
             when :traffic_time
               get_traffic_time
             when :distance
               get_distance
             when :directions
               list_all_directions
             when :step_by_step
               page_directions
      end
      [x, y]
    end

    def list_all_directions
      say_this = ''
      say_this << "~e:#{random_emoji('mappin', 'worldmap', 'car', 'bus', 'globe')} "
      say_this << "Okay! I'll list the directions for you."
      say_this << "\n\n"
      say_this << get_gmaps_data.step_list
      [get_gmaps_data, DismalTony::HandledResponse.finish(say_this)]
    end

    def page_directions; end

    def get_traffic_time
      req = get_gmaps_data
      t = req.duration

      badness = TrafficReportDirective::PATIENCE_LIMITS.find_all do |_k, v|
        v < t
      end.last.first

      moji_choice = case badness
                    when :none
                      random_emoji('100', 'star', 'thumbsup', 'car', 'clock', 'stopwatch')
                    when :low
                      random_emoji('clockface', 'stopwatch', 'mappin', 'worldmap', 'car')
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
                         synonym_for 'none'
                       when :low
                         synonym_for 'low'
                       when :medium
                         synonym_for 'medium'
                       when :high
                         synonym_for 'high'
                       when :very_high
                         synonym_for 'very high'
                       else
                         'harrowing'
      end

      say_this = ''
      say_this << "~e:#{moji_choice} "
      say_this << "The traffic on the way to #{parameters[:end_address]} is #{badness_string}. It will take #{time_str(t)} to get there."
      [get_gmaps_data, DismalTony::HandledResponse.finish(say_this)]
    end

    def get_distance
      req = get_gmaps_data
      moji_choice = random_emoji('mappin', 'worldmap', 'think')
      say_this = ''
      say_this << "~e:#{moji_choice} "
      say_this << "#{parameters[:end_address]} is #{d.convert('mi').round(2).to_f}mi away from #{parameters[:start_address]}."
      [get_gmaps_data, DismalTony::HandledResponse.finish(say_this)]
    end

    def check_shortcut(addr = '')
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

    def time_str(tim)
      hrs = Integer(tim.format('%h'))
      if hrs > 0
        tim.format('%h %~h and %m %~m')
      else
        tim.format('%m %~m')
      end
    end
  end
end
