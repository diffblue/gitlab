# frozen_string_literal: true

module AppSec
  module Dast
    module ScanConfigs
      class BuildService < BaseContainerService
        STAGE_NAME = 'dast'

        include Gitlab::Utils::StrongMemoize

        def execute
          return ServiceResponse.error(message: 'Dast site profile was not provided') unless dast_site_profile.present?
          return ServiceResponse.error(message: 'Cannot run active scan against unvalidated target') unless active_scan_allowed?

          ServiceResponse.success(
            payload: {
              dast_profile: dast_profile,
              branch: branch,
              ci_configuration: ci_configuration
            }
          )
        end

        private

        def active_scan_allowed?
          return true unless dast_scanner_profile&.active?

          url_base = DastSiteValidation.get_normalized_url_base(dast_site&.url)

          DastSiteValidationsFinder.new(
            project_id: container.id,
            state: :passed,
            url_base: url_base
          ).execute.present?
        end

        def branch
          strong_memoize(:branch) do
            dast_profile&.branch_name || params[:branch] || container.default_branch
          end
        end

        def ci_configuration
          ci_config = {
            'stages' => [STAGE_NAME],
            'include' => [{ 'template' => dast_template }],
            'dast' => {
              'dast_configuration' => { 'site_profile' => dast_site_profile.name, 'scanner_profile' => dast_scanner_profile&.name }.compact
            }
          }

          if Feature.enabled?(:on_demand_scans_runner_tags, container) && dast_profile&.tags.present?
            ci_config['dast']['tags'] = dast_profile.tag_list
          end

          ci_config.to_yaml
        end

        def dast_template
          if should_use_api_scan?
            'Security/DAST-On-Demand-API-Scan.gitlab-ci.yml'
          else
            'Security/DAST-On-Demand-Scan.gitlab-ci.yml'
          end
        end

        def should_use_api_scan?
          dast_site_profile.target_type == 'api'
        end

        def dast_profile
          strong_memoize(:dast_profile) do
            params[:dast_profile]
          end
        end

        def dast_site_profile
          strong_memoize(:dast_site_profile) do
            dast_profile&.dast_site_profile || params[:dast_site_profile]
          end
        end

        def dast_scanner_profile
          strong_memoize(:dast_scanner_profile) do
            dast_profile&.dast_scanner_profile || params[:dast_scanner_profile]
          end
        end

        def dast_site
          strong_memoize(:dast_site) do
            dast_site_profile.dast_site
          end
        end
      end
    end
  end
end
