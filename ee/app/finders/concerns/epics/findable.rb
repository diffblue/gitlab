# frozen_string_literal: true

# Module to include in epic finder classes to provide support
# for filtering and searching. Finder classes which use this module
# can use filter_and_search() method and pass it initial query for fetching epics.
# This initial query is different for each epics finder (legacy finder finds
# all epics in the same group hierarchy, ancestor epics finder finds only ancestor
# epics for given epic,...)

module Epics
  module Findable
    extend ActiveSupport::Concern

    include TimeFrameFilter
    include Gitlab::Utils::StrongMemoize
    extend ::Gitlab::Utils::Override

    IID_STARTS_WITH_PATTERN = %r{\A(\d)+\z}.freeze

    class_methods do
      def scalar_params
        @scalar_params ||= %i[
          parent_id
          author_id
          author_username
          label_name
          milestone_title
          start_date
          end_date
          search
          my_reaction_emoji
        ]
      end

      def array_params
        @array_params ||= { issues: [], label_name: [] }
      end

      def valid_iid_query?(query)
        query.match?(IID_STARTS_WITH_PATTERN)
      end
    end

    def klass
      Epic
    end

    private

    def filter_and_search(items)
      items = filter_items(items)
      items = filter_negated_items(items)

      # This has to be last as we use a CTE as an optimization fence
      # for counts by passing the force_cte param
      # https://www.postgresql.org/docs/current/static/queries-with.html
      by_search(items)
    end

    def milestone_groups
      raise NotImplementedError
    end

    def filter_items(items)
      items = by_created_at(items)
      items = by_updated_at(items)
      items = by_author(items)
      items = by_timeframe(items)
      items = by_state(items)
      items = by_label(items)
      items = by_parent(items)
      items = by_child(items)
      items = by_iids(items)
      items = by_my_reaction_emoji(items)
      items = by_confidential(items)
      items = by_milestone(items)

      starts_with_iid(items)
    end

    def filter_negated_items(items)
      # API endpoints send in `nil` values so we test if there are any non-nil
      return items unless not_params&.values&.any?

      by_negated_my_reaction_emoji(items)
    end

    def starts_with_iid(items)
      return items unless params[:iid_starts_with].present?

      query = params[:iid_starts_with]
      raise ArgumentError unless self.class.valid_iid_query?(query)

      items.iid_starts_with(query)
    end

    def parent_id?
      params[:parent_id].present?
    end

    def child_id?
      params[:child_id].present?
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def by_parent(items)
      if top_level_only? && !parent_id?
        items.left_outer_joins(:parent)
             .where.not(parent: { group_id: related_groups.as_ids })
             .or(items.where(parent_id: nil))
      elsif parent_id?
        items.where(parent_id: params[:parent_id])
      else
        items
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def by_child(items)
      return items unless child_id?

      hierarchy_order = params[:hierarchy_order] || :asc

      ancestors = Epic.find(params[:child_id]).ancestors(hierarchy_order: hierarchy_order)
      ancestors.where(id: items.select(:id))
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def by_confidential(items)
      return items if params[:confidential].nil?

      params[:confidential] ? items.confidential : items.public_only
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def by_milestone(items)
      return items unless params[:milestone_title].present?

      milestones = Milestone.for_projects_and_groups(milestone_group_projects, milestone_groups)
                            .where(title: params[:milestone_title])

      items.in_milestone(milestones)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def milestone_group_projects
      Project.in_namespace(milestone_groups).with_issues_available_for_user(current_user)
    end

    override :feature_flag_scope
    def feature_flag_scope
      params.group
    end

    def top_level_only?
      params.fetch(:top_level_hierarchy_only, false)
    end
  end
end
