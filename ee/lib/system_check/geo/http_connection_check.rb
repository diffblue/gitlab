# frozen_string_literal: true

module SystemCheck
  module Geo
    class HttpConnectionCheck < SystemCheck::BaseCheck
      set_name 'GitLab Geo HTTP(S) connectivity'

      NOT_SECONDARY_NODE = 'not a secondary node'
      GEO_NOT_ENABLED = 'Geo is not enabled'

      def skip?
        unless Gitlab::Geo.enabled?
          self.skip_reason = GEO_NOT_ENABLED

          return true
        end

        unless Gitlab::Geo.secondary?
          self.skip_reason = NOT_SECONDARY_NODE

          return true
        end

        false
      end

      def multi_check
        $stdout.puts
        $stdout.print '* Can connect to the primary node ... '
        check_gitlab_geo_node(Gitlab::Geo.primary_node)
      end

      private

      def check_gitlab_geo_node(node)
        response = Gitlab::HTTP.get(node.internal_uri, allow_local_requests: true, limit: 10)

        if response.code_type == Net::HTTPOK
          $stdout.puts 'yes'.color(:green)
        else
          $stdout.puts 'no'.color(:red)
        end
      rescue Errno::ECONNREFUSED => e
        display_exception(e)

        try_fixing_it(
          'Check if the machine is online and GitLab is running',
          'Check your firewall rules and make sure this machine can reach the target machine',
          "Make sure port and protocol are correct: '#{node.internal_url}', or change it in Admin > Geo Nodes"
        )
      rescue SocketError => e
        display_exception(e)

        if e.cause && e.cause.message.starts_with?('getaddrinfo')
          try_fixing_it(
            'Check if your machine can connect to a DNS server',
            "Check if your machine can resolve DNS for: '#{node.internal_uri.host}'",
            'If machine host is incorrect, change it in Admin > Geo Nodes'
          )
        end
      rescue OpenSSL::SSL::SSLError => e
        display_exception(e)

        try_fixing_it(
          'If you have a self-signed CA or certificate you need to whitelist it in Omnibus'
        )
        for_more_information(see_custom_certificate_doc)

        try_fixing_it(
          'If you have a valid certificate make sure you have the full certificate chain in the pem file'
        )
      rescue StandardError => e
        display_exception(e)
      end

      def display_exception(exception)
        $stdout.puts 'no'.color(:red)
        $stdout.puts '  Reason:'.color(:blue)
        $stdout.puts "  #{exception.message}"
      end

      def see_custom_certificate_doc
        'https://docs.gitlab.com/omnibus/common_installation_problems/index.html#using-self-signed-certificate-or-custom-certificate-authorities'
      end
    end
  end
end
