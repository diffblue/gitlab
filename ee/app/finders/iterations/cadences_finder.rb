# frozen_string_literal: true

# Search for iterations cadences

module Iterations
  class CadencesFinder
    attr_reader :current_user, :group, :params

    def initialize(current_user, group, params = {})
      @current_user = current_user
      @group = group
      @params = params
    end

    def execute
      raise ArgumentError, 'group argument is missing' unless group.present?

      items = Iterations::Cadence.all
      items = by_id(items)
      items = by_groups(items)
      items = by_title(items)
      items = by_duration(items)
      items = by_automatic(items)
      items = by_active(items)

      items.ordered_by_title
    end

    private

    def by_groups(items)
      items.with_groups(groups)
    end

    def groups
      groups = groups_to_include(group)

      groups_user_can_read_cadences(groups).map(&:id)
    end

    def groups_to_include(group)
      groups = [group]
      groups += group.ancestors if include_ancestor_groups?

      groups
    end

    def groups_user_can_read_cadences(groups)
      # `same_root` should be set only if we are sure that all groups
      # in related_groups have the same ancestor root group,
      # and here we get the group and its ancestors
      # https://gitlab.com/gitlab-org/gitlab/issues/11539
      Group.preset_root_ancestor_for(groups)

      DeclarativePolicy.user_scope do
        groups.select { |group| Ability.allowed?(current_user, :read_iteration_cadence, group) }
      end
    end

    def include_ancestor_groups?
      params[:include_ancestor_groups]
    end

    def by_id(items)
      return items if params[:id].blank?

      items.id_in(params[:id])
    end

    def by_title(items)
      return items if params[:title].blank?

      items.search_title(params[:title])
    end

    def by_duration(items)
      return items if params[:duration_in_weeks].blank?

      items.with_duration(params[:duration_in_weeks])
    end

    def by_automatic(items)
      return items if params[:automatic].nil?

      items.is_automatic(params[:automatic])
    end

    def by_active(items)
      return items if params[:active].nil?

      items.is_active(params[:active])
    end
  end
end
