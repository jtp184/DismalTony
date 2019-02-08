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

    # Returns a Query from raw text +txt+ and VIBase +vi+'s user
    def self.create_query(txt, vi = DismalTony.vi)
      Query.new(
        raw_text: txt,
        user: vi.user
      )
    end

    # Takes a Query +query+ and a VIBase +vi+ and uses the +vi+ to
    # execute a matching directive for +query+
    def self.run_match(query, vi)
      result = match(query, vi.directives)
      result = result.from(result.apply_parsing_strategies(query), vi)
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
        qry = create_query(txt, vi)
        run_match qry, vi
      else
        drek = DismalTony::Directives[st8.next_directive]
        qry = create_query(txt, vi)
        qry = st8.parse_next ? drek.apply_parsing_strategies(qry) : qry

        res = drek.new(qry, vi)
        res.parameters = st8.data
        res.call(st8.next_method.to_sym)
      end
    end
  end
end
