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
    Group
      .with_project_templates
      .self_and_ancestors
      .with_feature_available_in_plan(:group_project_templates)
      .self_and_descendants
  end

  def simple_group_search(groups)
    groups = group_id ? groups.find_by(id: group_id)&.self_and_ancestors : groups # rubocop: disable CodeReuse/ActiveRecord
    return Group.none unless groups

    groups.with_project_templates
  end
end
