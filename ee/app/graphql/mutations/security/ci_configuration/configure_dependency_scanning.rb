# frozen_string_literal: true

module Mutations
  module Security
    module CiConfiguration
      class ConfigureDependencyScanning < BaseSecurityAnalyzer
        graphql_name 'ConfigureDependencyScanning'
        description <<~DESC
          Configure Dependency Scanning for a project by enabling Dependency Scanning in a new or modified
          `.gitlab-ci.yml` file in a new branch. The new branch and a URL to
          create a Merge Request are a part of the response.
        DESC

        def configure_analyzer(project, **_args)
          ::Security::CiConfiguration::DependencyScanningCreateService.new(project, current_user).execute
        end
      end
    end
  end
end
