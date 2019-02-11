require 'dismaltony/parsing_strategies/aws_comprehend_strategy'
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
        @data_struct_template if @data_struct_template
        Struct::GoogleMapsRoute
      rescue NameError
        @data_struct_template ||= Struct.new('GoogleMapsRoute', :distance, :duration, :start_address, :end_address, :steps, :raw) do
          def step_list
            outp = ''
            steps.each_with_index do |_slug, ix|
              outp << "#{ix + 1}) " << step_string(ix) << " (#{time_string ix})" << "\n"
            end
            outp
          end

          def step_string(n)
            i = steps[n][:html_instructions].clone
            i.gsub!(%r{<([A-Z][A-Z0-9]*)\b[^>]*>(.*?)</\1>}i) { %(#{"\n\n" if Regexp.last_match(1) == 'div'}#{Regexp.last_match(2)}) }
            i
          end

          def time_string(n)
            i = steps[n][:duration][:text]
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
          mode: opts.fetch(:mode, 'driving'),
          departure_time: opts.fetch(:departure_time) { Time.now.to_i },
          alternatives: false
        ).first
        legs = req[:legs].first

        ds_args = []

        ds_args << Unit.new("#{legs[:distance][:value]}m").convert_to('mile').scalar.to_f.to_unit('mile')
        ds_args << Duration.new(second: legs[:duration_in_traffic][:value])
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
    include DismalTony::DirectiveHelpers::DataRepresentationHelpers
    include DismalTony::DirectiveHelpers::DataStructHelpers
    include DismalTony::DirectiveHelpers::ConversationHelpers
    include DismalTony::DirectiveHelpers::EmojiHelpers
    include DismalTony::DirectiveHelpers::GoogleMapsServiceHelpers

    PATIENCE_LIMITS = {
      none: 0.5,
      low: 1.0,
      medium: 2.0,
      high: 3.0,
      very_high: 4.0,
      harrowing: 4.8
    }.freeze

    set_name :traffic_report
    set_group :info

    expect_frags :start_address, :end_address

    use_parsing_strategies do |use|
      use << DismalTony::ParsingStrategies::ComprehendSyntaxStrategy
      use << DismalTony::ParsingStrategies::ComprehendTopicStrategy
      use << DismalTony::ParsingStrategies::ComprehendKeyPhraseStrategy
    end

    add_criteria do |qry|
      qry << uniquely { |q| q.contains?(/traffic/i) }
      qry << must { |q| q.locations? }
      qry << could { |q| q.contains?(/^time$/i, /^bad$/i, /^time$/i, /^long$/i) }
    end

    add_synonyms do |make|
      make[/^none$/i] = ['very light', 'quite low', 'very low', 'pretty good']
      make[/^low$/i] = ['low', 'not bad', 'light']
      make[/^medium$/i] = ['okay', 'not too bad', 'fine', 'decent']
      make[/^high$/i] = ['somewhat heavy', 'a bit dense', 'a bit clogged', 'heavy', 'high', 'dense']
      make[/^very high$/i] = ['backed up', 'very heavy', 'very high', 'highly dense', 'significant']
    end

    def run
      frags[:start_address] = query.locations.first.text
      frags[:end_address] = query.locations.last.text
      get_traffic_time
    end

    private

    def get_traffic_time
      req = gmaps_directions(start_address: frags[:start_address], end_address: frags[:end_address])
      return_data(req)
      t = (req.duration.total.to_f/60) / req.distance.scalar

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
                    when :harrowing
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
                       when :harrowing
                         'harrowing'
      end

      say_this = ''
      say_this << "~e:#{moji_choice} "
      say_this << "The traffic on the way to #{frags[:end_address]} is #{badness_string}. It will take #{time_str(req[:duration])} to get there."
      DismalTony::HandledResponse.finish(say_this)
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

  class MapsDirectionsDirective < DismalTony::Directive
    include DismalTony::DirectiveHelpers::DataRepresentationHelpers
    include DismalTony::DirectiveHelpers::DataStructHelpers
    include DismalTony::DirectiveHelpers::ConversationHelpers
    include DismalTony::DirectiveHelpers::EmojiHelpers
    include DismalTony::DirectiveHelpers::GoogleMapsServiceHelpers

    set_name :maps_directions
    set_group :info

    use_parsing_strategies do |use|
      use << DismalTony::ParsingStrategies::ComprehendSyntaxStrategy
      use << DismalTony::ParsingStrategies::ComprehendTopicStrategy
      use << DismalTony::ParsingStrategies::ComprehendKeyPhraseStrategy
    end

    add_criteria do |qry|
      qry << uniquely { |q| q.contains?(/directions/i, /route/i, /how do i get to/i) }
      qry << must { |q| q.locations? }
    end

    def run
      frags[:start_address] = query.locations.first.text
      frags[:end_address] = query.locations.last.text
      list_all_directions
    end

    private

    def list_all_directions
      req = gmaps_directions(start_address: frags[:start_address], end_address: frags[:end_address])
      return_data(req)

      say_this = ''
      say_this << "~e:#{random_emoji('mappin', 'worldmap', 'car', 'bus', 'globe')} "
      say_this << "Okay! I'll list the directions for you."
      say_this << "\n\n"
      say_this << req.step_list

      DismalTony::HandledResponse.finish(say_this)
    end
  end

  class GetDistanceDirective < DismalTony::Directive
    include DismalTony::DirectiveHelpers::DataRepresentationHelpers
    include DismalTony::DirectiveHelpers::DataStructHelpers
    include DismalTony::DirectiveHelpers::ConversationHelpers
    include DismalTony::DirectiveHelpers::EmojiHelpers
    include DismalTony::DirectiveHelpers::GoogleMapsServiceHelpers

    set_name :maps_distance
    set_group :info

    use_parsing_strategies do |use|
      use << DismalTony::ParsingStrategies::ComprehendSyntaxStrategy
      use << DismalTony::ParsingStrategies::ComprehendTopicStrategy
      use << DismalTony::ParsingStrategies::ComprehendKeyPhraseStrategy
    end

    add_criteria do |qry|
      qry << uniquely { |q| q.contains?(/^distance$/i, /^far$/i) }
      qry << must { |q| q.locations? }
    end

    def run
      frags[:start_address] = query.locations.first.text
      frags[:end_address] = query.locations.last.text
      get_distance
    end

    private

    def get_distance
      req = gmaps_directions(start_address: frags[:start_address], end_address: frags[:end_address])
      return_data(req)

      moji_choice = random_emoji('mappin', 'worldmap', 'think')
      say_this = ''
      say_this << "~e:#{moji_choice} "
      say_this << "#{frags[:end_address]} is #{req[:distance]} away from #{frags[:start_address]}."
      
      DismalTony::HandledResponse.finish(say_this)
    end   
  end
end
