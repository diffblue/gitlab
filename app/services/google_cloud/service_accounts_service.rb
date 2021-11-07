# frozen_string_literal: true

module GoogleCloud
  ##
  # This service deals with GCP Service Accounts in GitLab

  class ServiceAccountsService < ::BaseService
    ##
    # Find GCP Service accounts in a GitLab project
    #
    # This method looks up GitLab project's CI vars
    # and returns Google Cloud service accounts cominations
    # lining GitLab project and environment to GCP projects

    def find_for_project
      list = []
      group_vars_by_environment.each do |environment_scope, value|
        list.append({ environment: environment_scope,
                      gcp_project: value['GCP_PROJECT_ID'],
                      service_account_exists: !value['GCP_SERVICE_ACCOUNT'].nil?,
                      service_account_key_exists: !value['GCP_SERVICE_ACCOUNT_KEY'].nil? })
      end
      list
    end

    private

    def group_vars_by_environment
      gcp_keys = %w[GCP_PROJECT_ID GCP_SERVICE_ACCOUNT GCP_SERVICE_ACCOUNT_KEY]
      grouped = {}
      filtered_vars = @project.variables.filter { |variable| gcp_keys.include? variable.key }
      filtered_vars.each do |variable|
        unless grouped[variable.environment_scope]
          grouped[variable.environment_scope] = {}
        end

        grouped[variable.environment_scope][variable.key] = variable.value
      end
      grouped
    end
  end
end
