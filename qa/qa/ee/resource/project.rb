# frozen_string_literal: true

module QA
  module EE
    module Resource
      module Project
        include DoraMetrics

        # Get project push rules
        #
        # @return [Hash]
        def push_rules
          response = get(request_url(api_push_rules_path))
          parse_body(response)
        end

        # Add project push rules
        #
        # Rule list: https://docs.gitlab.com/ee/api/projects.html#add-project-push-rule
        #
        # @param [Hash] rules
        # @return [void]
        def add_push_rules(rules)
          api_post_to(api_push_rules_path, rules)
        end

        def api_push_rules_path
          "#{api_get_path}/push_rule"
        end

        # Set a compliance framework for the project
        #
        # @return [void]
        def compliance_framework=(framework)
          mutation = <<~GQL
            mutation {
              projectSetComplianceFramework(input: {
                complianceFrameworkId: "#{framework.gid}",
                projectId: "gid://gitlab/Project/#{id}"
              })
              {
                errors
                project {
                  id
                  complianceFrameworks {
                    nodes {
                      id
                      name
                    }
                  }
                }
              }
            }
          GQL

          api_post_to('/graphql', mutation)
        end
      end
    end
  end
end
