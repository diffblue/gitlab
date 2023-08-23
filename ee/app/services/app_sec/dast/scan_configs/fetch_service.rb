# frozen_string_literal: true

# Fetch dast scan configuration from ci yml file
module AppSec
  module Dast
    module ScanConfigs
      class FetchService < BaseProjectService
        def execute
          return ServiceResponse.error(message: _('Insufficient permissions')) unless allowed?

          dast_profile = fetch_dast_profile

          return ServiceResponse.error(message: errors) unless errors.empty?

          ServiceResponse.success(
            payload: {
              site_profile: dast_profile[:site_profile],
              scanner_profile: dast_profile[:scanner_profile]
            }
          )
        end

        private

        def allowed?
          Ability.allowed?(current_user, :read_on_demand_dast_scan, project)
        end

        def fetch_dast_profile
          fetch_from_policy || fetch_from_project_gitlab_ci_yml || not_found
        end

        def errors
          @errors ||= []
        end

        def fetch_from_policy
          policies = ::Security::ScanExecutionPoliciesFinder.new(
            current_user, project
          ).execute

          policies.map do |policy|
            next unless policy[:actions]

            policy[:actions].find { |action| action[:site_profile] || action[:scanner_profile] }
          end.compact.first
        end

        def fetch_from_project_gitlab_ci_yml
          return unless project.repository_exists?

          yml_dump = project.repository.gitlab_ci_yml_for(project.default_branch)

          result = ::Gitlab::Ci::YamlProcessor
            .new(yml_dump, project: project, user: current_user, sha: project.repository&.commit&.sha)
            .execute

          return errors.push(*result.errors) unless result.valid?

          dast_job = find_dast_job(result.jobs)

          return unless dast_job

          dast_job[:dast_configuration]
        end

        def not_found
          errors.push(_('DAST configuration not found'))
        end

        def find_dast_job(ci_jobs)
          ci_jobs.find { |_job_name, job| job.instance_of?(Hash) && job[:stage] == "dast" }&.last
        end
      end
    end
  end
end
