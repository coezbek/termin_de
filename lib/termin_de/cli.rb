# frozen_string_literal: true

require 'optparse'
require 'date'

module TerminDe
  # command line interface
  class Cli
    DEFAULT_DATE = Date.new(Date.today.year, Date.today.month + 2, 1)
    DEFAULT_DRY_RUN = false
    # default request for id card
    DEFAULT_SERVICE = '120703'

    # NOTE : We don't want to be limited by service protection
    REQUEST_INTERVAL_IN_SECONDS = 60

    DEFAULT_COMMAND = nil

    # By default we query all Bürgerämter
    BURGERAMT_IDS = '122210,122217,327316,122219,327312,122227,122231,327346,122238,122243,327348,122252,329742,122260,329745,122262,329748,122254,329751,122271,327278,122273,122277,327276,122280,327294,122282,327290,122284,327292,122291,327270,122285,327266,122286,327264,122296,327268,327262,325657,150230,329760,122301,327282,122297,327286,122294,327284,122312,329763,122304,327330,122311,327334,122309,327332,317869,324434,122281,327352,122279,122276,327324,122274,327326,122267,329766,122246,327318,122251,327320,327653,122257,327322,122208,122226'
    #[
    #  '122243', # Friedrichshain Frankfurter
    #  '122238', # Friedrichshain Schlesisches Tor
    #  '122260', # Lichtenberg Moellendorfstr
    #  '122262' # Lichtenberg TierparkCenter
    #]
    DEFAULT_VERBOSITY = false

    def initialize(argv)
      @argv = argv
      @options = Options.new(DEFAULT_DATE, DEFAULT_DRY_RUN, DEFAULT_SERVICE, BURGERAMT_IDS, DEFAULT_COMMAND, DEFAULT_VERBOSITY, REQUEST_INTERVAL_IN_SECONDS)
    end

    def start
      opt_parser.parse!(@argv)
      Loop.new(@options).run
    end

    private

    Options = Struct.new(:before_date, :dry_run, :service, :burgeramt, :command, :verbose, :request_interval_in_seconds) do
      def command_given?
        !command.nil?
      end

      alias_method :dry_run?, :dry_run
    end

    def opt_parser
      OptionParser.new do |parser|
        parser.version = VERSION
        parser.banner = "Burgeramt termin monitor. Version #{parser.version}\nUsage: termin_de [options]"

        parser.on('-b', '--before=<date>', String, 'Trigger only on date earlier than given date') do |date|
          @options.before_date = begin
                                   Date.parse(date)
                                 rescue StandardError
                                   DEFAULT_DATE
                                 end
        end

        parser.on('-c', '--execute=<command>', String, 'Run given command with %{date} and %{link} replacements') do |command|
          @options.command = command
        end

        parser.on('-s', '--service=<id>', String, 'Id of the requested service') do |id|
          @options.service = !id.nil? ? id : DEFAULT_SERVICE
        end

        parser.on('-u', '--burgeramt=<bid>', String, 'Id of the burgeramt(s) (comma separated)') do |id|
          @options.burgeramt = id.nil? ? BURGERAMT_IDS : id
        end

        parser.on('-i', '--interval=<sec>', String, 'How long to wait between requests in seconds') do |interval|
          @options.request_interval_in_seconds = interval.nil? ? REQUEST_INTERVAL_IN_SECONDS : interval
        end

        parser.on('--dry-run', 'Run on saved examples') do
          @options.dry_run = true
        end

        parser.on('--verbose', 'Print more information during run') do
          @options.verbose = true
        end

        parser.on_tail('--version', 'Display the version') do
          puts parser.version
          exit
        end
      end
    end
  end
end
