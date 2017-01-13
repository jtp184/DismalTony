require 'json'

class QueryHandler
  attr_accessor :handler_name
  attr_accessor :verbs
  attr_accessor :patterns
  attr_accessor :data

  def check_understanding(query)
    parse query
    response = 'Okay, I got:\n\n'
    data.keys.each do |key|
      response += "  #{key}: #{data[key]}\n"
    end
    response
  end

  def parse(query)
    match_data = nil

    verbs.each_with_index do |verb, pattern_index|
      if query.downcase.include? verb
        match_data = patterns[pattern_index].match query
      end
    end

    data.keys.each do |key|
      data[key] = match_data[key]
    end
  end

  def register_verbs
    # TODO: Add all verbs to a registry to prevent collisions
    verbs.each do |verb|
      # Register Verb
    end
  end

  def from_json(json_string)
    new_object = QueryHandler.new

    hashed = JSON.parse(json_string)
    new_object.handler_name = hashed['handler_name']
    new_object.verbs = hashed['verbs']
    # new_object.register_verbs
    new_object.patterns = hashed['patterns']
    new_object.patterns.map! { |e| Regexp.new(e, Regexp::IGNORECASE) }

    new_object.data = unpack_data hashed['data']

    new_object
  end

  def unpack_data(data)
    resolved = {}
    data.each do |member|
      k = member['key']
      case member['type']
      when 'string'
        resolved[k] = ''
      when 'number'
        resolved[k] = 0
      end
    end
    resolved
  end

  def from_json!(json_string)
    hashed = JSON.parse(json_string)
    self.handler_name = hashed['handler_name']
    self.verbs = hashed['verbs']
    # self.register_verbs
    self.patterns = hashed['patterns']
    patterns.map! { |e| Regexp.new(e, Regexp::IGNORECASE) }
    self.data = (unpack_data hashed['data'])
    self
  end
end

handle = QueryHandler.new
handle.from_json!(File.readlines('ex_handler.json').join('\n'))

puts handle.check_understanding 'put mario on friday afternoon'
