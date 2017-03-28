module Utilities
  module Time
    require 'active_support/inflector' # Contains `pluralize`

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
  class String
    # Converts camel case (eg. TextLikeThis) to underscored versions (eg. text_like_this).
    def underscore
      self.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
    end
  end
end
