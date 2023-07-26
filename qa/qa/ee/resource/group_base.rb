# frozen_string_literal: true

module QA
  module EE
    module Resource
      module GroupBase
        include DoraMetrics

        # Get group epics
        #
        # @return [Array<QA::EE::Resource::Epic>]
        def epics
          parse_body(api_get_from(api_epics_path)).map do |epic|
            Epic.init do |resource|
              resource.group = self
              resource.api_client = api_client
              resource.id = epic[:id]
              resource.iid = epic[:iid]
              resource.title = epic[:title]
              resource.description = epic[:description]
            end
          end
        end

        # Get group iterations
        #
        # @return [Array<QA::EE::Resource::GroupIteration>]
        def iterations
          parse_body(api_get_from(api_iterations_path)).map do |iteration|
            GroupIteration.init do |resource|
              resource.group = self
              resource.api_client = api_client
              resource.id = iteration[:id]
              resource.iid = iteration[:iid]
              resource.title = iteration[:title]
              resource.description = iteration[:description]
            end
          end
        end

        def api_epics_path
          "#{api_get_path}/epics"
        end

        def api_iterations_path
          "#{api_get_path}/iterations"
        end

        def api_delete_path
          if marked_for_deletion?
            "#{super}?permanently_remove=true&full_path=#{CGI.escape(full_path)}"
          else
            super
          end
        end

        # Check if the group has already been scheduled to be deleted
        #
        # @return [Boolean]
        def marked_for_deletion?
          reload!.api_response[:marked_for_deletion_on].present?
        end

        # Remove the group unless it's already scheduled for deletion.
        def remove_via_api!(force: false)
          if marked_for_deletion? && !force
            QA::Runtime::Logger.debug("#{self.class.name} #{identifier} is already scheduled to be removed.")

            return
          end

          super()
        end

        # Immediately removes a sandboxed group if it is scheduled for deletion.
        def immediate_remove_via_api!
          raise 'Cannot immediately delete top level groups' unless respond_to?(:sandbox)

          remove_via_api!
          remove_via_api!(force: true)
        end

        # Get all compliance frameworks in the group
        #
        # @return [Array<QA::EE::Resource::ComplianceFramework>]
        def compliance_frameworks
          response = process_api_response(
            api_post_to(
              '/graphql',
              <<~GQL
                query {
                  group(fullPath: "#{full_path}") {
                    complianceFrameworks {
                      nodes {
                        id
                        name
                        description
                        color
                        default
                        pipelineConfigurationFullPath
                      }
                    }
                  }
                }
              GQL
            )
          )
          response[:nodes].map do |node|
            QA::EE::Resource::ComplianceFramework.init do |framework|
              # `id` field format: "gid://gitlab/ComplianceManagement::Framework/:id"
              framework.id = node[:id].rpartition('/')[2]
              framework.group = self
              framework.name = node[:name]
              framework.description = node[:description]
              framework.color = node[:color]
              framework.default = !!node[:default]
              framework.pipeline_configuration_full_path = node[:pipelineConfigurationFullPath]
            end.reload!
          end
        end
      end
    end
  end
end
