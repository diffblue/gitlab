# frozen_string_literal: true

class LinkedEpicEntity < Grape::Entity
  include RequestAwareEntity

  expose :id, :iid, :title, :state, :created_at, :closed_at

  expose :reference do |epic|
    epic.to_reference(request.issuable.group)
  end

  expose :path do |epic|
    group_epic_path(epic.group, epic)
  end

  expose :relation_path do |epic|
    group_epic_link_path(request.issuable.group, request.issuable.iid, epic.id)
  end

  expose :has_children do |epic|
    epic.has_children?
  end

  expose :has_issues do |epic|
    epic.has_issues?
  end

  expose :full_path do |epic|
    epic.group.full_path
  end

  expose :can_admin do |epic|
    can?(request.current_user, :admin_epic_tree_relation, epic)
  end
end
