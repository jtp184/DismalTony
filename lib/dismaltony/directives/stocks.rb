require 'dismaltony/parsing_strategies/aws_comprehend_strategy'
require 'uri'
require 'date'
require 'net/http'
require 'json'
require 'ostruct'
require 'numbers_in_words'
require 'numbers_in_words/duck_punch'

module DismalTony::DirectiveHelpers # :nodoc:
  # Uses the AlphaVantage API to get StockPrices
  module StocksHelpers
    include HelperTemplate

    # The Class methods of the helper, included on module inclusion
    module ClassMethods
      # A Struct which stores the price data retrieved
      StockPrice = Struct.new(:symbol, :date, :open, :high, :low, :close, :volume) do
        include Comparable

        def price
          close || open
        end

        def <=>(other)
          close <=> other.close
        rescue NoMethodError
          close <=> Integer(other)
        end

        def to_s
          price.to_s
        end

        def to_str
          price.to_s
        end
      end

      # Converts +args+ to a StockPrice
      def stock_price(*args)
        StockPrice.new(*args)
      end
    end

    # The Instance methods of the hlper, included on module inclusion
    module InstanceMethods
      # Retrieves data for given query params +qpr+
      def retrieve_data(qpr)
        parse_web_req(api_request(qpr))
      end

      # Does a SYMBOL_SEARCH to get information
      def symbol_search(srch)
        req = api_request(
          function: 'SYMBOL_SEARCH',
          keywords: srch
        )
        req = req['bestMatches']

        req = req.first
                 .transform_keys { |k| k.split(/\d\.\s(\w+)/) }
                 .transform_keys(&:last)
                 .transform_keys(&:underscore)
                 .transform_keys(&:to_sym)
      end

      # Takes in the web response +resp+ and parses it as JSON
      def parse_web_req(resp)
        jsr = resp
        sym = jsr['Meta Data']['2. Symbol']
        slug = jsr.to_a[1].last

        results = []

        slug.each do |dat, prindx|
          md = /(\d+)-(\d+)-(\d+)/.match dat
          datum = Date.new(md[1].to_i, md[2].to_i, md[3].to_i)
          results << stock_price(sym, datum, *prindx.values.map(&:to_f))
        end
        results
      end

      # Class-instance version of .stock_price
      def stock_price(*args)
        self.class.send(:stock_price, *args)
      end
    end
  end
end

module DismalTony::Directives # :nodoc:
  # Uses the AlphaVantageAPI to get the current stock price
  class GetStockPriceDirective < DismalTony::Directive
    include DismalTony::DirectiveHelpers::JSONAPIHelpers
    include DismalTony::DirectiveHelpers::ConversationHelpers
    include DismalTony::DirectiveHelpers::DataRepresentationHelpers
    include DismalTony::DirectiveHelpers::EmojiHelpers
    include DismalTony::DirectiveHelpers::StocksHelpers

    set_name :get_stock_price
    set_group :info

    expect_frags :stock_id, :stock_name, :current_value

    use_parsing_strategies do |use|
      use << DismalTony::ParsingStrategies::ComprehendSyntaxStrategy
      use << DismalTony::ParsingStrategies::ComprehendTopicStrategy
    end

    add_criteria do |qry|
      qry << uniquely { |q| q =~ /stocks?/i }
      qry << must(&:organization?)
    end

    add_synonyms do |make|
      make[/today's/i] = ['the current', "today's", 'the', 'current']
    end

    set_api_url 'https://www.alphavantage.co/query'

    set_api_defaults do |adef|
      adef[:function] = 'TIME_SERIES_DAILY'
      adef[:apikey] = ENV['ALPHA_VANTAGE_KEY'] || ENV['alpha_vantage_key']
    end

    # Gets the org, retrieves the symbol for it, and returns data
    def run
      org = symbol_search(query.organization.text)
      frags[:stock_id] = org[:symbol]
      frags[:stock_name] = org[:name]

      prices = retrieve_data(symbol: frags[:stock_id])

      frags[:current_value] = prices.max_by(&:date)

      return_data(OpenStruct.new)

      data_representation.value = frags[:current_value]
      data_representation.price = frags[:current_value].price
      data_representation.symbol = frags[:stock_id]
      data_representation.name = frags[:stock_name]

      answ, moj = price_comment(prices)

      conv = "~e:#{moj} "
      conv << synonym_for("today's").capitalize
      conv << " stock price for #{frags[:stock_name]} (#{frags[:stock_id]}) is "
      conv << answ << '.'
      DismalTony::HandledResponse.finish(conv)
    end

    private

    # Takes in downloaded +history+ and creates a randomized response for it
    def price_comment(history)
      current = history.max_by(&:date)

      comment = "$#{format('%.2f', current.price)}" 

      fluff = case [0, 1, 2, 3].sample
              when 0
               with_delta(history)
              when 1
               with_highest(history)
              else
                [
                  '',
                  random_emoji('moneywing', 'moneybag', 'monocle', 'tophat', 'dollarsign')
                ]
              end

      comment << fluff[0]

      [comment, fluff[1]]
    end

    # Adds a delta addendum for +history+
    def with_delta(history)
      yesterday = history.sort_by(&:date).reverse[1]
      current = history.max_by(&:date)

      if current > yesterday
        [
          ", up from yesterday's $#{yesterday.price}",
          random_emoji('chartup', 'thumbsup', 'fire')
        ]
      else
        [
          ", down from yesterday's $#{yesterday.price}",
          random_emoji('chartdown', 'raincloud', 'snail')
        ]
      end
    end

    # Adds a highest value addendum for +history+
    def with_highest(history)
      current = history.max_by(&:date)

      if history.max == current
        [
          ', currently at its 100-day peak',
          random_emoji('star', 'rocket', '100')
        ]
      else
        [
          ", with a 100-day peak of $#{history.max.price} on #{history.max.date}",
          random_emoji('barchart', 'chartup', 'checkbox')
        ]
      end
    end
  end

  # Determines the value of a specific number of shares of a stock
  class StockMathDirective < DismalTony::Directive
    include DismalTony::DirectiveHelpers::EmojiHelpers
    include DismalTony::DirectiveHelpers::ConversationHelpers
    include DismalTony::DirectiveHelpers::InterrogativeHelpers
    include DismalTony::DirectiveHelpers::DataRepresentationHelpers
    include DismalTony::DirectiveHelpers::DataStructHelpers
    include DismalTony::DirectiveHelpers::JSONAPIHelpers
    include DismalTony::DirectiveHelpers::StocksHelpers

    set_name :stock_math
    set_group :info

    expect_frags :stock_id, :stock_name, :current_value, :shares_requested, :final_total

    use_parsing_strategies do |use|
      use << DismalTony::ParsingStrategies::ComprehendSyntaxStrategy
      use << DismalTony::ParsingStrategies::ComprehendTopicStrategy
    end

    add_criteria do |qry|
      qry << uniquely { |q| q.contains?(/stocks?/i, /shares?/i) }
      qry << must(&:quantity?)
      qry << must(&:organization?)
      qry << could { |q| q.contains?(/shares?/i) }
    end

    add_synonyms do |make|
      make [/^is worth/i] = ['would be worth', 'is worth', 'are worth', 'come out to', 'are valued at']
    end

    set_api_url 'https://www.alphavantage.co/query'

    set_api_defaults do |adef|
      adef[:function] = 'TIME_SERIES_DAILY'
      adef[:apikey] = ENV['ALPHA_VANTAGE_KEY'] || ENV['alpha_vantage_key']
    end

    # Gets the stock symbol and the quantity, does the calculation, and finalizes
    def run
      org = symbol_search(query.organization.text)
      frags[:stock_id] = org[:symbol]
      frags[:stock_name] = org[:name]

      num = query.quantity.text

      num = if num =~ /\d/
              Integer(num.match(/\d+/).to_s)
            else
              num.in_numbers
            end

      if num < 1
        ask_for_shares_requested(
          message: "~e:pound Please enter the number of shares you'd like to sum as a digit.",
          cast: -> (q) { frags[:shares_requested] ||= q.quantity.text.in_numbers }
        )
      else
        frags[:shares_requested] = num
        finalize
      end

      return ask_frags if ask_frags

      finalize
    end

    private

    # Performs final calculation for value, and sets their returns
    def finalize
      frags[:current_value] = retrieve_data(symbol: frags[:stock_id]).first
      
      resp = nil
      resp = calculate_final_total

      return_data(OpenStruct.new)
      
      data_representation[:value] = frags[:current_value]
      data_representation[:name] = frags[:stock_name]
      data_representation[:shares_requested] = frags[:shares_requested]
      data_representation[:answer] = frags[:final_total]

      %i[to_i to_int].each do |k|
        data_representation[k] = data_representation[:answer]
      end

      resp
    end

    # Sets final total for response, including HandledResponse
    def calculate_final_total
      frags[:final_total] = (frags[:shares_requested] * frags[:current_value].price)
     
      moj = random_emoji(
        'chartup',
        'lightbulb',
        'magnifyingglass',
        'moneywing',
        'moneybag',
        'pencil',
        'think',
        'tophat',
        'monocle',
        'toast'
      )

      fstring = ""
      fstring << "~e:#{moj} "
      fstring << frags[:shares_requested].to_s
      fstring << " shares of "
      fstring << "#{frags[:stock_name]} (#{frags[:stock_id]})"
      fstring << " stock "
      fstring << synonym_for('is worth')
      fstring << " $#{frags[:final_total]}"

      DismalTony::HandledResponse.finish(fstring)
    end
  end
end
