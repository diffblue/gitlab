# frozen_string_literal: true

module QA
  module EE
    module Resource
      module GroupBase
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
      end
    end
  end
end
