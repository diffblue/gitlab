# frozen_string_literal: true
class GroupsWithTemplatesFinder
  def initialize(group_id = nil)
    @group_id = group_id
  end

  def execute
    if ::Gitlab::CurrentSettings.should_check_namespace_plan?
      groups = extended_group_search
      simple_group_search(groups)
    else
      simple_group_search(Group.all)
    end
  end

  private

  attr_reader :group_id

  def extended_group_search
    groups = Group.with_project_templates
    groups_with_plan = Gitlab::ObjectHierarchy
      .new(groups)
      .base_and_ancestors
      .with_feature_available_in_plan(:group_project_templates)

    # We're adding an extra query that will be removed once we remove the feature flag in https://gitlab.com/gitlab-org/gitlab/-/issues/339439
    if ::Feature.enabled?(:linear_groups_template_finder_extended_group_search, current_group, default_enabled: :yaml)
      groups_with_plan.self_and_descendants
    else
      Gitlab::ObjectHierarchy.new(groups_with_plan).base_and_descendants
    end
  end

  def simple_group_search(groups)
    groups = group_id ? groups.find_by(id: group_id)&.self_and_ancestors : groups # rubocop: disable CodeReuse/ActiveRecord
    return Group.none unless groups

    groups.with_project_templates
  end

  # This method will be removed https://gitlab.com/gitlab-org/gitlab/-/issues/339439
  def current_group
    Group.find_by(id: group_id) # rubocop:disable CodeReuse/ActiveRecord
  end
end
