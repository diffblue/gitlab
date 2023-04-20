# frozen_string_literal: true

module SystemCheck
  module Geo
    class ClocksSynchronizationCheck < SystemCheck::BaseCheck
      include ::SystemCheck::MultiCheckHelpers

      set_name 'Machine clock is synchronized'

      attr_reader :ntp_host, :ntp_port, :ntp_timeout

      def initialize
        @ntp_host = ENV.fetch('NTP_HOST', 'pool.ntp.org')
        @ntp_port = ENV.fetch('NTP_PORT', 'ntp')
        @ntp_timeout = ENV.fetch('NTP_TIMEOUT', Net::NTP::TIMEOUT).to_i
      end

      def multi_check
        if ntp_request.offset.abs < max_clock_difference

          print_pass
          return true
        end

        print_failure("Clocks are not in sync with #{ntp_host} NTP server")
        try_fixing_it(
          'Enable an NTP update service on this machine to keep clocks synchronized'
        )

        for_more_information('administration/geo/replication/troubleshooting#health-check-rake-task')

        false
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError
        print_warning("NTP Server #{ntp_host} cannot be reached")
        show_ntp_connection_error
      rescue Timeout::Error
        print_warning("Connection to the NTP Server #{ntp_host} took more than #{ntp_timeout} seconds (Timeout)")
        show_ntp_connection_error
      end

      def show_ntp_connection_error
        try_fixing_it(
          "Check whether you have a connectivity problem or if there is a firewall blocking it",
          "If this is an offline environment, you can ignore this error, " \
          "but make sure you have a way to keep clocks synced."
        )

        for_more_information('administration/geo/replication/troubleshooting#health-check-rake-task')
      end

      private

      def ntp_request
        Net::NTP.get(ntp_host, ntp_port, ntp_timeout)
      end

      def max_clock_difference
        Gitlab::Geo::SignedData::LEEWAY
      end
    end
  end
end
