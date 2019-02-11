require 'dismaltony/parsing_strategies/aws_comprehend_strategy'
require 'uri'
require 'date'
require 'net/http'
require 'json'
require 'ostruct'
require 'numbers_in_words'
require 'numbers_in_words/duck_punch'

module DismalTony::DirectiveHelpers
  module StocksHelpers
    include HelperTemplate
    
    module ClassMethods
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

      def stock_price(*args)
        StockPrice.new(*args)
      end
    end

    module InstanceMethods
      def retrieve_data(qpr)
        parse_web_req(api_request(qpr))
      end

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

      def stock_price(*args)
        self.class.stock_price(*args)
      end
    end
  end
end

module DismalTony::Directives
  class GetStockPriceDirective < DismalTony::Directive
    include DismalTony::DirectiveHelpers::JSONAPIHelpers
    include DismalTony::DirectiveHelpers::ConversationHelpers
    include DismalTony::DirectiveHelpers::DataRepresentationHelpers
    include DismalTony::DirectiveHelpers::EmojiHelpers
    include DismalTony::DirectiveHelpers::StocksHelpers

    set_name :get_stock_price
    set_group :info

    expect_frags :stock_id, :current_value

    use_parsing_strategies do |use|
      use << DismalTony::ParsingStrategies::ComprehendSyntaxStrategy
      use << DismalTony::ParsingStrategies::ComprehendTopicStrategy
    end

    add_criteria do |qry|
      qry << uniquely { |q| q =~ /stocks?/i }
      qry << must { |q| q.organization? }
    end

    add_synonyms do |make|
      make[/today's/i] = ['the current', "today's", 'the', 'current']
    end

    set_api_url 'https://www.alphavantage.co/query'

    set_api_defaults do |adef|
      adef[:function] = 'TIME_SERIES_DAILY'
      adef[:apikey] = ENV['alpha_vantage_key']
    end

    def run
      frags[:stock_id] = query.organization.text
      prices = retrieve_data(symbol: frags[:stock_id])

      frags[:current_value] = prices.max_by(&:date)

      return_data(OpenStruct.new)

      data_representation.value = frags[:current_value]
      data_representation.price = frags[:current_value].price
      data_representation.symbol = frags[:stock_id]

      answ, moj = price_comment(prices)

      conv = "~e:#{moj} "
      conv << synonym_for("today's").capitalize
      conv << " stock price for #{frags[:stock_id]} is "
      conv << answ << '.'
      DismalTony::HandledResponse.finish(conv)
    end

    private

    def price_comment(history)
      current = history.max_by(&:date)
      moj = ''

      comment = "$#{format('%.2f', current.price)}" << case [0, 1, 2, 3].sample
                                                       when 0
                                                         # Better / worse than yesterday
                                                         yesterday = history.sort_by(&:date).reverse[1]
                                                         if current > yesterday
                                                           moj = random_emoji('chartup', 'thumbsup', 'fire')
                                                           ", up from yesterday's $#{yesterday.price}"
                                                         else
                                                           moj = random_emoji('chartdown', 'raincloud', 'snail')
                                                           ", down from yesterday's $#{yesterday.price}"
                                                         end
                                                       when 1
                                                         # Compared to highest record
                                                         if history.max == current
                                                           moj = random_emoji('star', 'rocket', '100')
                                                           ', currently at its 100-day peak'
                                                         else
                                                           moj = random_emoji('barchart', 'chartup', 'checkbox')
                                                           ", with a 100-day peak of $#{history.max.price} on #{history.max.date}"
                                                         end
                                                       else
                                                         # Just the current price, no commentary
                                                         moj = random_emoji('moneywing', 'moneybag', 'monocle', 'tophat', 'dollarsign')
                                                         ''
       end
      [comment, moj]
     end
  end

  class StockMathDirective < DismalTony::Directive
    include DismalTony::DirectiveHelpers::JSONAPIHelpers
    include DismalTony::DirectiveHelpers::ConversationHelpers
    include DismalTony::DirectiveHelpers::DataStructHelpers
    include DismalTony::DirectiveHelpers::DataRepresentationHelpers
    include DismalTony::DirectiveHelpers::EmojiHelpers
    include DismalTony::DirectiveHelpers::StocksHelpers

    set_name :stock_math
    set_group :info

    expect_frags :stock_id, :current_value, :shares_requested, :final_total

    use_parsing_strategies do |use|
      use << DismalTony::ParsingStrategies::ComprehendSyntaxStrategy
      use << DismalTony::ParsingStrategies::ComprehendTopicStrategy
    end

    add_criteria do |qry|
      qry << uniquely { |q| q.contains?(/stocks?/i, /shares?/i) }
      qry << must { |q| q.quantity? }
      qry << must { |q| q.organization? }
      qry << could { |q| q.contains(/shares?/i)}
    end

    add_synonyms do |make|
      make [/^is worth/i] = ['would be worth', 'is worth', 'are worth', 'come out to', 'are valued at']
    end

    set_api_url 'https://www.alphavantage.co/query'

    set_api_defaults do |adef|
      adef[:function] = 'TIME_SERIES_DAILY'
      adef[:apikey] = ENV['alpha_vantage_key']
    end

    def run
      frags[:stock_id] ||= query.organization.text

      num = query.quantity.text
      if num =~ /\d/
        frags[:shares_requested] = Integer(num.match(/\d+/).to_s)
      else
        frags[:shares_requested] = num.in_numbers
      end

      if frags[:shares_requested] < 1
        ask_for_number
      else
        finalize
      end
    end

    private

    def finalize
      frags[:current_value] = retrieve_data(symbol: frags[:stock_id]).first

      resp = nil
      resp = calculate_final_total
      return_data(OpenStruct.new)

      data_representation[:stock_data] = frags[:current_value]
      data_representation[:shares_requested] = frags[:shares_requested]
      data_representation[:answer] = frags[:final_total]
      data_representation[:to_int] = data_representation[:to_i] = data_representation[:answer]

      resp
    end

    def calculate_final_total
      frags[:final_total] = (frags[:shares_requested] * frags[:current_value].price)
      moj = random_emoji('chartup', 'lightbulb', 'magnifyingglass', 'moneywing', 'moneybag', 'pencil', 'think', 'tophat', 'monocle', 'toast')
      x = DismalTony::HandledResponse.finish("~e:#{moj} #{frags[:shares_requested]} shares of #{frags[:stock_id]} stock #{synonym_for('is worth')} $#{frags[:final_total]}")
    end

    def ask_for_number
      DismalTony::HandledResponse.then_do(
        message: "~e:pound Please enter the number of shares you'd like to sum as a digit.",
        directive: self,
        method: :read_number,
        data: frags
      )
    end

    def read_number
      frags[:shares_requested] ||= query.quantity.text.in_numbers
      finalize
    rescue ArgumentError
      ask_for_number
    end
  end
end
