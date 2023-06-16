# frozen_string_literal: true

module QA
  module EE
    module Resource
      class ScanResultPolicyCommit < QA::Resource::Base
        attributes :policy_yaml,
          :mode,
          :policy_name,
          :project_path

        MAX_MUTATION_RETRY_ATTEMPTS = 3

        def initialize
          @mutation_retry_attempts = 0
        end

        def resource_web_url(resource)
          super
        rescue ResourceURLMissingError
          # this particular resource does not expose a web_url property
        end

        # Defining api_get_path because it is required to be overridden for an api resource class
        #
        # @return [String]
        def api_get_path
          "/graphql"
        end

        # Graphql mutation for vulnerability item creation
        #
        # @return [String]
        def api_post_body
          <<~GQL
            mutation {
                scanExecutionPolicyCommit(
                   input: {
                    name: "#{policy_name}",
                    fullPath: "#{project_path}",
                    operationMode: #{mode},
                    policyYaml: "#{policy_yaml.to_yaml}"
                  }
                ) {
                  branch
                  errors
                }
              }
          GQL
        end

        # Overrides QA::Resource::ApiFabricator#api_post
        #
        # @return [Hash]
        def api_post
          super
        rescue ResourceFabricationFailedError => e
          raise unless e.message.include?('Required approvals exceed eligible approvers')
          raise if @mutation_retry_attempts >= MAX_MUTATION_RETRY_ATTEMPTS

          # The error above can be raised if project authorization isn't updated quickly enough.
          # See https://gitlab.com/gitlab-org/gitlab/-/issues/413667
          @mutation_retry_attempts += 1
          sleep 5
          retry
        end

        # GraphQl endpoint to create a Scan result policy commit
        alias_method :api_post_path, :api_get_path
      end
    end
  end
end
