# frozen_string_literal: true

module EE
  module Resolvers
    module Ci
      module RunnersResolver
        extend ::Gitlab::Utils::Override

        prepended do
          include ::Gitlab::Graphql::Authorize::AuthorizeResource
        end

        override :ready?
        def ready?(sort: nil, type: nil, **args)
          check_sort_conditions(type) if sort == :most_active_desc

          super
        end

        def resolve(**args)
          # keyset pagination doesn't really make sense for most_active_desc sorting
          # as it requires counting ci_running_builds anyway
          # and it's very hard to implement
          return offset_pagination(super) if args[:sort]&.to_s == 'most_active_desc'

          super
        end

        private

        def check_sort_conditions(type)
          if type != 'instance_type'
            raise ::Gitlab::Graphql::Errors::ArgumentError,
              'MOST_ACTIVE_DESC sorting is only available when type is INSTANCE_TYPE'
          end

          return if License.feature_available?(:runner_performance_insights)

          raise_resource_not_available_error!(
            'runner_performance_insights feature is required for MOST_ACTIVE_DESC sorting'
          )
        end
      end
    end
  end
end
