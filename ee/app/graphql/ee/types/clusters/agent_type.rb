# frozen_string_literal: true
module EE
  module Types
    module Clusters
      module AgentType
        extend ActiveSupport::Concern

        prepended do
          field :vulnerability_images,
                type: ::Types::Vulnerabilities::ContainerImageType.connection_type,
                null: true,
                description: 'Container images reported on the agent vulnerabilities.',
                resolver: ::Resolvers::Vulnerabilities::ContainerImagesResolver
        end
      end
    end
  end
end
