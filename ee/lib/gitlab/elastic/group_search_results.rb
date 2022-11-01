# frozen_string_literal: true

module Gitlab
  module Elastic
    # Always prefer to use the full class namespace when specifying a
    # superclass inside a module, because autoloading can occur in a
    # different order between execution environments.
    class GroupSearchResults < Gitlab::Elastic::SearchResults
      extend Gitlab::Utils::Override

      attr_reader :group, :default_project_filter, :filters

      # rubocop:disable Metrics/ParameterLists
      def initialize(current_user, query, limit_project_ids = nil, group:, public_and_internal_projects: false, default_project_filter: false, order_by: nil, sort: nil, filters: {})
        @group = group
        @default_project_filter = default_project_filter
        @filters = filters

        super(current_user, query, limit_project_ids, public_and_internal_projects: public_and_internal_projects, order_by: order_by, sort: sort, filters: filters)
      end
      # rubocop:enable Metrics/ParameterLists

      override :scope_options
      def scope_options(scope)
        case scope
        when :issues
          super.merge(group_ids: [group.id])
        when :users
          super.merge(groups: group.self_and_hierarchy_intersecting_with_user_groups(current_user))
        else
          super
        end
      end
    end
  end
end
