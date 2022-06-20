# frozen_string_literal: true

module QA
  module EE
    module Resource
      class ScanResultPolicyProject < QA::Resource::Base
        attributes :project_path

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
             mutation{
                  securityPolicyProjectCreate(input: { fullPath: "#{project_path}" }) {
                    project {
                      id
                      fullPath
                      branch: repository {
                        rootRef
                      }
                    }
                    project {
                    id
                    name
                    }
                    errors
                  }
                }
          GQL
        end

        # GraphQl endpoint to create a vulnerability
        alias_method :api_post_path, :api_get_path
      end
    end
  end
end
