# frozen_string_literal: true
module Gitlab
  module Graphql
    module Extensions
      class ForwardOnlyExternallyPaginatedArrayExtension < ExternallyPaginatedArrayExtension
        def apply
          field.argument :after, GraphQL::Types::String,
            description: "Returns the elements in the list that come after the specified cursor.",
            required: false
          field.argument :first, GraphQL::Types::Int,
            description: "Returns the first _n_ elements from the list.",
            required: false
        end
      end
    end
  end
end
