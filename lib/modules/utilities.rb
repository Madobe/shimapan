module Utilities
  module Time
    # Parses a given string for its value in seconds. Converts one-character time units into seconds.
    # @param string [String] The string to be parsed.
    def parse_time_string(string)
      if string.scan(/\D/).empty?
        return string.to_i
      else
        modifiers = { "s" => 1, "m" => 60, "h" => 3600, "d" => 86400 }
        return string[0..-2].to_i * modifiers[string[-1]]
      end
    end
  end
end
