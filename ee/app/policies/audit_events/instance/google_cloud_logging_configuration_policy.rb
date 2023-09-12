# frozen_string_literal: true

module AuditEvents
  module Instance
    class GoogleCloudLoggingConfigurationPolicy < BasePolicy
      delegate { :global }
    end
  end
end
