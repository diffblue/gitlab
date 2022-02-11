# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Enable SSL verification for CI integrations with known-good hostnames.
    class BackfillIntegrationsEnableSslVerification
      INTEGRATIONS = {
        # This matches the logic in `Integrations::DroneCi#url_is_saas?`
        # https://docs.drone.io/pipeline/environment/reference/drone-system-hostname/
        'DroneCiService' => [
          :drone_url,
          /\Acloud\.drone\.io\z/i.freeze
        ],
        # This matches the logic in `Integrations::Teamcity#url_is_saas?`
        # https://www.jetbrains.com/help/teamcity/cloud/migrate-from-teamcity-on-premises-to-teamcity-cloud.html#Migration+Process
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
        integrations = Integration.affected.where(id: (start_id..stop_id))

        integrations.each do |integration|
          next unless integration.properties

          url_field, known_hostnames = INTEGRATIONS.fetch(integration.type)

          url = integration.properties[url_field.to_s]
          next unless url.present?

          begin
            parsed_url = Addressable::URI.parse(url)
          rescue Addressable::URI::InvalidURIError
            next
          end

          next unless parsed_url.scheme == 'https' && parsed_url.hostname =~ known_hostnames

          integration.properties['enable_ssl_verification'] = true

          begin
            integration.save!(touch: false)
          rescue ActiveRecord::RecordInvalid
            # Don't change the configuration if the record is invalid, in this case
            # they will just keep having SSL verification disabled.
          end
        end

        mark_job_as_succeeded(start_id, stop_id)
      end

      private

      def mark_job_as_succeeded(*arguments)
        Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
          self.class.name.demodulize,
          arguments
        )
      end
    end
  end
end
