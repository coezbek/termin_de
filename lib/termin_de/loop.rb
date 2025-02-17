# frozen_string_literal: true

require 'logger'
require 'yaml'

module TerminDe
  # Endless loop for querying the burgeramt webpage
  class Loop

    def initialize(options)
      @options = options
      @fails = 0

      TerminDe.logger.datetime_format = '%Y-%m-%d %H:%M:%S'
      TerminDe.logger.level = options.verbose ? Logger::DEBUG : Logger::INFO

      TerminDe.logger.debug "Starting with options:\n#{options.to_h.to_yaml}"

    end

    def run
      infinitly do
        calendar = Calendar.new(@options)

        if calendar.earlier?
          termin_found(calendar.earlier_termin)
        else
          TerminDe.logger.info 'Nothing ...'
        end

        sleep(@options.request_interval_in_seconds)
      end
    end

    private

    def infinitly
      loop do
        TerminDe.logger.info "Looking for available slots for service #{@options.service}, in #{@options.burgeramt == Cli::BURGERAMT_IDS ? 'all buergeramts' : "buergeramt #{@options.burgeramt}"} before #{@options.before_date}"
        begin
          yield
        rescue Exception => e
          # NOTE : Arrrgh, Curb doesn't nest exceptions
          raise unless e.class.name =~ /Curl/

          @fails += 1
          pause_when(@fails)
        end
      end
    end

    def pause_when(fails)
      num = (Math.log10(fails) * @options.request_interval_in_seconds / 2 + @options.request_interval_in_seconds).to_i
      TerminDe.logger.warn "Woooops, slow down ... pause for #{num} seconds"
      sleep(num)
    end

    def termin_found(termin)
      TerminDe.logger.info "Found new [#{termin.date}] → #{termin.link}"
      print "\a"
      `#{@options.command % termin.to_h}` if @options.command_given?
    end
  end
end
