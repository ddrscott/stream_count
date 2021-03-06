require 'stream_count/version'

# Collects IO stats from stdin and prints the stats to stderr.
# Original stdin is output to stdout.
#
# rubocop:disable all
module StreamCount
  module_function

  BUFFER_SIZE   = 10240
  TICK_DURATION = 0.2

  # Do the work
  def run(io = ARGF)
    @start_time = Time.now.to_f
    bytes = 0
    lines = 0
    output(bytes: bytes, lines: lines)
    while (data = io.read(BUFFER_SIZE))
      $stdout.write(data)
      bytes += data.size
      lines += data.count($/)
      throttler { output(bytes: bytes, lines: lines) }
    end
    output(bytes: bytes, lines: lines)
  end

  # output formatted stats to stderr.
  # Using throttle will limit how often we print to stderr to 5/second.
  def output(bytes:, lines:)
    msg = "\e[1G\e[2K%s seconds | %s bytes [ %s kb/sec ] | %s lines [ %s lines/sec ]"
    duration = Time.now.to_f - @start_time
    if duration > 0
      $stderr.print(msg % [number_with_delimiter(duration.to_i),
                           number_with_delimiter(bytes),
                           number_with_delimiter((bytes / duration / 1024).to_i),
                           number_with_delimiter(lines),
                           number_with_delimiter((lines / duration).to_i)])
    end
  end

  def throttler(threshold: TICK_DURATION)
    @last_tick ||= Time.now.to_f
    if Time.now.to_f > (@last_tick + threshold)
      yield
      @last_tick = Time.now.to_f
    end
  end

  # Thanks ActiveSupport::NumberHelper
  def number_with_delimiter(number, delimiter = ',')
    number.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
  end
end
