# frozen_string_literal: true

module Gitlab
  module AlertManagement
    def self.custom_mapping_available?(project)
      project.feature_available?(:multiple_alert_http_integrations)
    end

    # Returns the complete list of alert fields for the custom mapping to be consumed by the frontend and the GraphQL API.
    #
    # @see https://docs.gitlab.com/ee/operations/incident_management/integrations.html#customize-the-alert-payload-outside-of-gitlab
    # @return [Array<Hash>]
    def self.alert_fields
      [
        {
          name: 'title',
          label: 'Title',
          description: 'The title of the incident.',
          types: %w[string]
        },
        {
          name: 'description',
          label: 'Description',
          description: 'A high-level summary of the problem.',
          types: %w[string]
        },
        {
          name: 'start_time',
          label: 'Start time',
          description: 'The time of the incident.',
          types: %w[datetime]
        },
        {
          name: 'end_time',
          label: 'End time',
          description: 'The resolved time of the incident.',
          types: %w[datetime]
        },
        {
          name: 'service',
          label: 'Service',
          description: 'The affected service.',
          types: %w[string]
        },
        {
          name: 'monitoring_tool',
          label: 'Monitoring tool',
          description: 'The name of the associated monitoring tool.',
          types: %w[string]
        },
        {
          name: 'hosts',
          label: 'Hosts',
          description: 'One or more hosts, as to where this incident occurred.',
          types: %w[string array]
        },
        {
          name: 'severity',
          label: 'Severity',
          description: 'The severity of the alert.',
          types: %w[string]
        },
        {
          name: 'fingerprint',
          label: 'Fingerprint',
          description: 'The unique identifier of the alert. This can be used to group occurrences of the same alert.',
          types: %w[string array]
        },
        {
          name: 'gitlab_environment_name',
          label: 'Environment',
          description: 'The name of the associated GitLab environment.',
          types: %w[string]
        }
      ]
    end
  end
end
