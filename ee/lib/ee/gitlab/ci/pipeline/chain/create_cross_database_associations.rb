# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Pipeline
        module Chain
          module CreateCrossDatabaseAssociations
            extend ::Gitlab::Utils::Override
            include ::Gitlab::Ci::Pipeline::Chain::Helpers

            override :perform!
            def perform!
              create_dast_configuration_associations
            end

            override :break?
            def break?
              pipeline.errors.any?
            end

            private

            def create_dast_configuration_associations
              pipeline.builds.each do |build|
                response = find_dast_profiles(build)

                error(response.errors.join(', '), config_error: true) if response.error?
                next if response.error? || response.payload.blank?

                build.dast_site_profile = response.payload[:dast_site_profile]
                build.dast_scanner_profile = response.payload[:dast_scanner_profile]
              end
            rescue StandardError => e
              ::Gitlab::ErrorTracking.track_exception(e, extra: { pipeline_id: pipeline.id })

              error('Failed to associate DAST profiles')
            end

            def find_dast_profiles(build)
              dast_configuration = build.options[:dast_configuration]

              return ServiceResponse.success unless dast_configuration && build.stage == 'dast'

              AppSec::Dast::Profiles::BuildConfigService.new(
                project: pipeline.project,
                current_user: pipeline.user,
                params: {
                  dast_site_profile: dast_configuration[:site_profile],
                  dast_scanner_profile: dast_configuration[:scanner_profile]
                }
              ).execute
            end
          end
        end
      end
    end
  end
end
