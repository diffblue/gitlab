# frozen_string_literal: true

module Gitlab
  module Ci
    class RunnerReleases
      include Singleton

      RELEASES_VALIDITY_PERIOD = 1.day
      RELEASES_VALIDITY_AFTER_ERROR_PERIOD = 5.seconds

      def initialize
        reset!
      end

      # Returns a sorted list of the publicly available GitLab Runner releases
      #
      def releases
        return @releases unless Time.current >= @expire_time

        response = Gitlab::HTTP.try_get(::Gitlab::CurrentSettings.current_application_settings.public_runner_releases_url)

        @releases = response.success? ? extract_releases(response) : nil
        @expire_time = (@releases ? RELEASES_VALIDITY_PERIOD : RELEASES_VALIDITY_AFTER_ERROR_PERIOD).from_now

        @releases
      end

      def reset!
        @expire_time = Time.current
        @releases = nil
      end

      public_class_method :instance

      private

      def extract_releases(response)
        response.parsed_response.map { |release| parse_runner_release(release) }.sort!
      end

      def parse_runner_release(release)
        ::Gitlab::VersionInfo.parse(release['name'].delete_prefix('v'))
      end
    end
  end
end
