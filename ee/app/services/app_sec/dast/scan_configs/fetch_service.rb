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

          result = ::Gitlab::Ci::Lint
            .new(project: project, current_user: current_user)
            .validate(yml_dump)

          return errors.push(*result.errors) unless result.valid?

          gitlab_ci_yml = load_yml(result.merged_yaml || '{}')

          dast_job = find_dast_job(gitlab_ci_yml)

          return unless dast_job

          dast_job[:dast_configuration]
        end

        def not_found
          errors.push(_('DAST configuration not found'))
        end

        def find_dast_job(gitlab_ci_yml)
          gitlab_ci_yml.find { |_, v| v.instance_of?(Hash) && v[:stage] == "dast" }&.last
        end

        def load_yml(data)
          ::Gitlab::Ci::Config::Yaml.load!(data)
        rescue ::Gitlab::Config::Loader::FormatError
          errors.push(_('The parsed YAML is too big'))
        end
      end
    end
  end
end
