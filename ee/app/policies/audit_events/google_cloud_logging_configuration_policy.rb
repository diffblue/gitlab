# frozen_string_literal: true

module AuditEvents
  class GoogleCloudLoggingConfigurationPolicy < ::BasePolicy
    delegate { @subject.group }
  end
end
