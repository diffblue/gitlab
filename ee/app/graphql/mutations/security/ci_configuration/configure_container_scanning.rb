# frozen_string_literal: true

module Mutations
  module Security
    module CiConfiguration
      class ConfigureContainerScanning < BaseSecurityAnalyzer
        graphql_name 'ConfigureContainerScanning'
        description <<~DESC
          Configure Container Scanning for a project by enabling Container Scanning in a new or modified
          `.gitlab-ci.yml` file in a new branch. The new branch and a URL to
          create a merge request are part of the response.
        DESC

        def configure_analyzer(project, **_args)
          ::Security::CiConfiguration::ContainerScanningCreateService.new(project, current_user).execute
        end
      end
    end
  end
end
