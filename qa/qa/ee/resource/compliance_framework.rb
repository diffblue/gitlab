# frozen_string_literal: true

module QA
  module EE
    module Resource
      class ComplianceFramework < QA::Resource::Base
        attribute :group do
          QA::Resource::Group.fabricate_via_api! do |group|
            group.path = "compliance-frameworks-#{SecureRandom.hex(8)}"
          end
        end

        attribute :id
        attribute :name
        attribute :description
        attribute :color
        attribute :default
        attribute :pipeline_configuration_full_path

        def initialize
          @name = Faker::Lorem.unique.sentence
          @description = "This is a test Compliance Framework"
          @color = "#6699cc"
          @default = false
          @pipeline_configuration_full_path = nil
        end

        def resource_web_url(resource)
          super
        rescue ResourceURLMissingError
          # this particular resource does not expose a web_url property
        end

        def gid
          "gid://gitlab/ComplianceManagement::Framework/#{id}"
        end

        def api_get_path
          "/graphql"
        end

        def api_post_path
          api_get_path
        end

        def api_post_body
          <<~GQL
            mutation {
              createComplianceFramework(input: {
                namespacePath: "#{group.full_path}"
                params: {
                  color: "#{color}"
                  default: #{default}
                  description: "#{description}"
                  name: "#{name}"
                  #{pipeline_configuration_path_param}
                }
              })
              {
                errors
                framework {
                  id
                  color
                  default
                  description
                  name
                  pipelineConfigurationFullPath
                }
              }
            }
          GQL
        end

        def api_update_body
          <<~GQL
            mutation {
              updateComplianceFramework(input: {
                id: "#{gid}"
                params: {
                  color: "#{color}"
                  default: #{default}
                  description: "#{description}"
                  name: "#{name}"
                  #{pipeline_configuration_path_param}
                }
              })
              {
                errors
                complianceFramework {
                  id
                  color
                  default
                  description
                  name
                  pipelineConfigurationFullPath
                }
              }
            }
          GQL
        end

        def remove_via_api!(delete_default: false)
          # Can't delete a default framework so if we want to do that we must first update it so it's not default
          if delete_default
            @default = false
            api_post_to(api_post_path, api_update_body)
          end

          api_delete
        end

        def api_delete_path
          api_get_path
        end

        def api_delete_body
          <<~GQL
            mutation {
              destroyComplianceFramework(input: { id: "#{gid}" }) {
                errors
              }
            }
          GQL
        end

        def pipeline_configuration_path_param
          return unless pipeline_configuration_full_path

          %(pipelineConfigurationFullPath: "#{pipeline_configuration_full_path}")
        end
      end
    end
  end
end
