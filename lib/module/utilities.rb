module Utilities
  require 'active_support/inflector' # Contains `pluralize`

  module Time
    # Parses a given string for its value in seconds. Converts one-character time units into seconds.
    # @param string [String] The string to be parsed.
    def self.to_seconds(string)
      if string.scan(/\D/).empty?
        return string.to_i
      else
        modifiers = { "s" => 1, "m" => 60, "h" => 3600, "d" => 86400 }
        return string[0..-2].to_i * modifiers[string[-1]]
      end
    end

    def self.humanize(seconds)
      return "0 seconds" if seconds <= 0
      [[86400, 'day'], [3600, 'hour'], [60, 'minute'], [1, 'second']].map { |divisor, unit|
        n, seconds = seconds.divmod(divisor)
        "#{n} #{unit.pluralize(n)}" if n > 0
      }.compact.join(', ')
    end
  end

  # Add new methods directly to the String class.
  class ::String
    # Prepends a timestamp to the front of a string.
    # @option backticks [Boolean] Whether to surround the timestamp in backticks (Discord
    # formatting).
    def timestamp(backticks = true)
      template = backticks ? "`[%s]` %s" : "[%s] %s"
      template % [::Time.now.utc.strftime("%H:%M:%S"), self]
    end
  end
end
