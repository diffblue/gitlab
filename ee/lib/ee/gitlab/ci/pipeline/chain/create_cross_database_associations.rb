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
              create_dast_associations
            end

            override :break?
            def break?
              pipeline.errors.any?
            end

            private

            def create_dast_associations
              # we don't use pipeline.stages.by_name because it introduces an extra sql query
              dast_stage = pipeline.stages.find { |stage| stage.name == ::AppSec::Dast::ScanConfigs::BuildService::STAGE_NAME }
              return unless dast_stage

              # we use dast_stage.statuses to avoid extra sql queries
              dast_stage.statuses.each do |status|
                next unless status.is_a?(::Ci::Build)

                associate_dast_profiles(dast_stage, status)
              end
            end

            def associate_dast_profiles(stage, build)
              response = find_dast_profiles(build)

              error(response.errors.join(', '), config_error: true) if response.error?
              return if response.error? || response.payload.blank?

              dast_site_profile = response.payload[:dast_site_profile]
              Dast::SiteProfilesBuild.create!(ci_build: build, dast_site_profile: dast_site_profile) if dast_site_profile

              dast_scanner_profile = response.payload[:dast_scanner_profile]
              Dast::ScannerProfilesBuild.create!(ci_build: build, dast_scanner_profile: dast_scanner_profile) if dast_scanner_profile
            rescue ActiveRecord::ActiveRecordError => e
              ::Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e, extra: { pipeline_id: pipeline.id })

              error('Failed to associate DAST profiles')
            end

            def find_dast_profiles(build)
              dast_configuration = build.options[:dast_configuration]
              return ServiceResponse.success unless dast_configuration

              AppSec::Dast::Profiles::BuildConfigService.new(
                project: build.project,
                current_user: build.user,
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
