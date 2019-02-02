module DismalTony
  # The class that handles assembly of Query objects, and combining them with directives.
  # This class is where the primary matching logic defined by the MatchLogic
  # objects is executed, and Directive#run calls are made.
  module QueryResolver
    # The usual version of the matching function.
    # Takes in a +query+ and set of +directives+, and checks to see the matches.
    # It automatically sorts by highest yielding Directive, and omits directives which returned nil.
    def self.match(query, directives)
      succeeds = match!(query, directives)
      succeeds.reject! { |_d, p| p.nil? }
      succeeds = succeeds.max_by(&:last)
      raise NoDirectiveError, 'No Matching Directive!' unless succeeds
      succeeds.first
    end

    # A debugging version of the #match function, this takes the same +query+ and +directives+
    # parameters and returns an array of the Directive and its corresponding yield.
    def self.match!(query, directives)
      succeeds = directives.map { |d| [d, d =~ query] }
    end

    # Returns a Query for +user+ without trying to parse +txt+
    def self.query_from_text(txt, user)
      Query.new(
        raw_text: txt,
        user: user.clone
      )
    end

    # Returns a new Query for a given UserIdentity +user+ and input string +txt+.
    # Tries to use ParseyParse to parse +txt+ and provide the result.
    def self.query_from_text!(txt, user)
      Query.new(
        raw_text: txt,
        parsed_result: ParseyParse.call(txt),
        user: user.clone
      )
    end

    # Takes a Query +query+ and a VIBase +vi+ and uses the +vi+ to
    # execute a matching directive for +query+
    def self.run_match(query, vi)
      result = match(query, vi.directives)
      result = result.from(query, vi)
      result.call
    rescue NoDirectiveError
      Directive.error(query, vi)
    end

    # Given an input string +txt+ and an input VIBase +vi+, this function disambiguates forced
    # return states, and creates a Query and runs it using #run_match. Uses the ConversationState
    # to determine whether to parse the query or not, as well as whether to forcibly select a Directive
    def self.call(txt, vi)
      st8 = vi.user.clone.state

      if st8.idle?
        qry = query_from_text!(txt, vi.user)
        run_match qry, vi
      else
        qry = if st8.parse_next
                query_from_text!(txt, vi.user)
              else
                query_from_text(txt, vi.user)
              end
        res = DismalTony::Directives[st8.next_directive].new(qry, vi)
        res.parameters = st8.data
        res.call(st8.next_method.to_sym)
      end
    end
  end
end
