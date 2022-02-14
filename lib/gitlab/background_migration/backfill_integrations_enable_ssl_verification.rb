# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Enable SSL verification for CI integrations with known-good hostnames.
    class BackfillIntegrationsEnableSslVerification
      INTEGRATIONS = {
        # This matches the logic in `Integrations::DroneCi#url_is_saas?`
        # - https://gitlab.com/gitlab-org/gitlab/blob/65b7fc1ad1ad33247890324e9a3396993b7718a1/app/models/integrations/drone_ci.rb#L122-127
        # - https://docs.drone.io/pipeline/environment/reference/drone-system-hostname/
        'DroneCiService' => [
          :drone_url,
          /\Acloud\.drone\.io\z/i.freeze
        ],
        # This matches the logic in `Integrations::Teamcity#url_is_saas?`
        # - https://gitlab.com/gitlab-org/gitlab/blob/65b7fc1ad1ad33247890324e9a3396993b7718a1/app/models/integrations/teamcity.rb#L117-122
        # - https://www.jetbrains.com/help/teamcity/cloud/migrate-from-teamcity-on-premises-to-teamcity-cloud.html#Migration+Process
        'TeamcityService' => [
          :teamcity_url,
          /\A[^\.]+\.teamcity\.com\z/i.freeze
        ]

        # Other CI integrations which don't seem to have a SaaS offering:
        # - Atlassian Bamboo (the SaaS offering is Bitbucket Pipelines)
        # - Jenkins (self-hosted only)
        # - MockCi (development only)
      }.freeze

      # Define the `Integration` model
      class Integration < ActiveRecord::Base
        include EachBatch

        self.table_name = :integrations
        self.inheritance_column = :_type_disabled

        serialize :properties, JSON

        scope :affected, -> { where(type: INTEGRATIONS.keys).where.not(properties: nil) }
      end

      def perform(start_id, stop_id)
        integration_ids = Integration
          .affected
          .where(id: (start_id..stop_id))
          .pluck(:id)

        integration_ids.each do |id|
          Integration.transaction do
            integration = Integration.lock.find(id)
            process_integration(integration)
          end
        end

        mark_job_as_succeeded(start_id, stop_id)
      end

      private

      def process_integration(integration)
        url_field, known_hostnames = INTEGRATIONS.fetch(integration.type)

        url = integration.properties[url_field.to_s]
        return unless url.present?

        parsed_url = Addressable::URI.parse(url)
        return unless parsed_url.scheme == 'https' && parsed_url.hostname =~ known_hostnames

        integration.properties['enable_ssl_verification'] = true

        integration.save!(touch: false)
      rescue Addressable::URI::InvalidURIError, ActiveRecord::RecordInvalid
        # Don't change the configuration if the record is invalid, in this case
        # they will just keep having SSL verification disabled.
      end

      def mark_job_as_succeeded(*arguments)
        Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
          self.class.name.demodulize,
          arguments
        )
      end
    end
  end
end
