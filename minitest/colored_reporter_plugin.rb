# Just a little custom reporting for Minitest. Adds color and spec-style print-outs so it's easier
# to see if anything's wrong in a glance.
module Minitest
  class ColoredReporter < ::Minitest::StatisticsReporter
    RESULT_CODE_TO_COLOR = {
      'S' => :yellow,
      '.' => :green,
      'F' => :red,
      'E' => :red
    }

    COLOR_CODE = {
      red: 31,
      green: 32,
      yellow: 33,
      blue: 34,
      none: 0
    }

    def record(result)
      super

      if @class_name != result.class.name
        @class_name = result.class.name
        io.print "%s\n" % @class_name
      end

      result_name = result.name.gsub(/^test_\d{4}_/, "  ")
      result_code = result.result_code
      io.print color("%s\n" % result_name, RESULT_CODE_TO_COLOR[result_code])
    end

    def color(text, color = :none)
      code = COLOR_CODE[color]
      "\e[#{code}m#{text}\e[0m"
    end

    def report
      super

      io.puts "\n"
      io.puts statistics
      io.puts aggregated_results
      io.puts summary
    end

    def statistics
      "Finished in %.6fs, %.4f runs/s, %.4f assertions/s." % [total_time, count / total_time, assertions / total_time]
    end

    def aggregated_results
      filtered_results = results.sort_by {|result| result.skipped? ? 1 : 0 }

      filtered_results.each_with_index.map { |result, i|
        color("\n%3d) %s" % [i+1, result], result.skipped? ? :yellow : :red)
      }.join + "\n"
    end

    def summary
      summary = "%d runs, %d assertions, %d failures, %d errors, %d skips" % [count, assertions, failures, errors, skips]

      color = :green
      color = :yellow if skips > 0
      color = :red if errors > 0 || failures > 0

      color(summary, color)
    end
  end

  def self.plugin_colored_reporter_init(options)
    Minitest.reporter.reporters.clear
    Minitest.reporter << ColoredReporter.new(options[:io], options)
  end
end
