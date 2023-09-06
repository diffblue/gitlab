# frozen_string_literal: true

module AuditEvents
  module Instance
    class GoogleCloudLoggingConfiguration < ApplicationRecord
      include Limitable
      include ExternallyCommonDestinationable
      include GcpExternallyDestinationable

      self.limit_name = 'google_cloud_logging_configurations'
      self.limit_scope = Limitable::GLOBAL_SCOPE
      self.table_name = 'audit_events_instance_google_cloud_logging_configurations'

      validates :log_id_name, uniqueness: { scope: :google_project_id_name }
      validates :name, uniqueness: true
    end
  end
end
