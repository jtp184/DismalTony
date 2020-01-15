require 'dismaltony/parsing_strategies/aws_comprehend_strategy'

module DismalTony::Directives
	class TipMathDirective < DismalTony::Directive
		include DismalTony::DirectiveHelpers::DataRepresentationHelpers
		include DismalTony::DirectiveHelpers::InterrogativeHelpers
		include DismalTony::DirectiveHelpers::EmojiHelpers

		set_name :tip_math
		set_group :money_math

		expect_frags :bill_subtotal, :tip, :tip_total, :bill_total

		use_parsing_strategies do |use|
			use << DismalTony::ParsingStrategies::ComprehendSyntaxStrategy
			use << DismalTony::ParsingStrategies::ComprehendTopicStrategy
		end

		add_criteria do |qry|
			qry << uniquely { |q| q.contains?(/^tip$/i) }
			qry << must { |q| q.contains?(/^bill/i, /^check/i) }
			qry << could(&:quantities?)
		end

		def run
			moj = random_emoji('dollarsign', 'moneybag', 'moneywing', 'pencil')
			ask_for_bill_subtotal(
				message: "~e:#{moj} How much is the bill?",
				cast: ->(a) { Float(/(?:\$)?([\d\.]*)/.match(a)[1]) }
			) 
			
			moj = random_emoji('moneybag', 'moneywing', 'present', 'martini', 'dollarsign')
			ask_for_tip(
				message: "~e:#{moj} How much would you like to tip?",
				cast: ->(a) { Integer(/(\d+)\%?/.match(a)[1]) * 0.01 }
			)

			if query.quantities?
				possible_matches = {
					bill_subtotal: /(?:\$)([\d\.]*)/,
					tip: /(\d+)\% tip/
				}

				possible_matches.each do |key, matcher|
					next if frags[key]&.value
					srch = query.raw_text.match(matcher)
					frags[key].original = srch[1] if srch
				end
			end

			return ask_frags if ask_frags

			perform_calculations
			
			result = fragments.to_h
												.slice(:tip_total, :bill_total)
												.transform_values { |v| v.round(2) }

			return_data(result)

			moj = random_emoji('taco', 'takeout', 'sandwich', 'pizza', 'fries')

			str = "~e:#{moj} "
			str << "Okay! The tip is #{monetize result[:tip_total]}"
			str << " and the total is #{monetize result[:bill_total]}"

			DismalTony::HandledResponse.finish(str)
		end

		private

		def perform_calculations
			frags[:bill_total] = (frags[:bill_subtotal].value * (1.0 + frags[:tip].value))
			frags[:tip_total] = (frags[:bill_subtotal].value * frags[:tip].value)

			fragments
		end

		def monetize(val)
			"$%.2f" % val
		end
	end

	class BillSplitDirective < DismalTony::Directive
		include DismalTony::DirectiveHelpers::DataRepresentationHelpers
		include DismalTony::DirectiveHelpers::InterrogativeHelpers
		include DismalTony::DirectiveHelpers::EmojiHelpers
		include DismalTony::DirectiveHelpers::ConversationHelpers

		set_name :bill_split
		set_group :money_math

		expect_frags :bill_subtotal, :split_count, :tip, :tip_total, :bill_total, :per_person_total

		use_parsing_strategies do |use|
			use << DismalTony::ParsingStrategies::ComprehendSyntaxStrategy
			use << DismalTony::ParsingStrategies::ComprehendTopicStrategy
		end

		add_criteria do |qry|
			qry << must { |q| q.contains?(/^split$/i) }
			qry << should { |q| q.contains?(/^bill$/i, /^check$/i) }
			qry << could(&:quantities?)
		end

		add_synonyms do |syn|
			syn[/cost of/i] = [
				'How much is the bill?',
				"What's the price of the check?"
			] 

			syn[/tip for/i] = [
				"What percent are you tipping?",
				'Tip at what percent?',
			]

			syn[/split between/i] = [
				"How many ways is the bill split?",
				"Split between how many people?",
				"Split the check how many ways?"
			]
		end

		def run
			moj = random_emoji('dollarsign', 'moneybag', 'moneywing', 'pencil')

			ask_for_bill_subtotal(
				message: "~e:#{moj} #{synonym_for('cost of')}",
				cast: ->(a) { Float(/(?:\$)?([\d\.]*)/.match(a)[1]) }
			) 
			
			moj = random_emoji('pound', 'user', 'users')
			
			ask_for_split_count(
				message: "~e:#{moj} #{synonym_for('split between')}",
				cast: ->(a) { Integer(a) }
			) 
			
			moj = random_emoji('moneybag', 'moneywing', 'present', 'martini', 'dollarsign')
			
			ask_for_tip(
				message: "~e:#{moj} #{synonym_for('tip for')}",
				cast: ->(a) { Integer(/(\d+)\%?/.match(a)[1]) * 0.01 }
			)

			if query.quantities?
				possible_matches = {
					bill_subtotal: /\$([\d\.]{1,5})/,
					split_count: /(\d+) (?:people|ways)/,
					tip: /(\d+)\% tip/
				}

				possible_matches.each do |key, matcher|
					next if frags[key]&.value
					srch = query.raw_text.match(matcher)
					frags[key].original = srch[1] if srch
				end
			end

			return ask_frags if ask_frags

			perform_calculations
			
			result = fragments.to_h.slice(:tip_total, :bill_total, :per_person_total).transform_values { |v| v.round(2) }

			return_data(result)

			moj = random_emoji('taco', 'takeout', 'sandwich', 'pizza', 'fries')

			str = "~e:#{moj} "
			str << "Okay! The tip is #{monetize result[:tip_total]}"
			str << ", the total is #{monetize result[:bill_total]}"
			str << ", and the amount per person is #{monetize result[:per_person_total]}"

			DismalTony::HandledResponse.finish(str)
		end

		private

		def perform_calculations
			frags[:bill_total] = (frags[:bill_subtotal].value * (1.0 + frags[:tip].value))
			frags[:tip_total] = (frags[:bill_subtotal].value * frags[:tip].value)
			frags[:per_person_total] = (frags[:bill_total] / frags[:split_count].value)

			fragments
		end

		def monetize(val)
			"$%.2f" % val
		end
	end
end