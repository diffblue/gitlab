# frozen_string_literal: true

module RemoteDevelopment
  module AgentConfig
    class LicenseChecker
      include Messages

      # @param [Hash] value
      # @return [Result]
      def self.check_license(value)
        if License.feature_available?(:remote_development)
          # Pass along the value to the next step
          Result.ok(value)
        else
          Result.err(LicenseCheckFailed.new)
        end
      end
    end
  end
end
