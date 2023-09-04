# frozen_string_literal: true

module AuditEvents
  class GoogleCloudLoggingConfiguration < ApplicationRecord
    include Limitable
    include ExternallyCommonDestinationable
    include GcpExternallyDestinationable

    self.limit_name = 'google_cloud_logging_configurations'
    self.limit_scope = :group
    self.table_name = 'audit_events_google_cloud_logging_configurations'

    belongs_to :group, class_name: '::Group', foreign_key: 'namespace_id',
      inverse_of: :google_cloud_logging_configurations

    validates :google_project_id_name, uniqueness: { scope: [:namespace_id, :log_id_name] }

    validates :name, uniqueness: { scope: :namespace_id }

    validate :root_level_group?

    private

    def root_level_group?
      errors.add(:group, 'must not be a subgroup') if group.subgroup?
    end
  end
end
