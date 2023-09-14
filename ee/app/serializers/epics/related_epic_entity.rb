# frozen_string_literal: true

module Epics
  class RelatedEpicEntity < Grape::Entity
    include Gitlab::Utils::StrongMemoize
    include RequestAwareEntity

    expose :id, :confidential, :title, :state, :created_at, :closed_at

    expose :relation_path do |related_epic|
      if can_admin_epic_link_relation?(related_epic)
        group_epic_related_epic_link_path(issuable.group, issuable.iid, related_epic.related_epic_link_id)
      end
    end

    expose :reference do |related_epic|
      related_epic.to_reference(request.issuable.group)
    end

    expose :path do |related_epic|
      group_epic_path(related_epic.group, related_epic)
    end

    expose :link_type do |related_epic|
      related_epic.epic_link_type
    end

    private

    def can_admin_epic_link_relation?(epic)
      user = request.current_user

      Ability.allowed?(user, :admin_epic_link_relation, issuable) &&
        Ability.allowed?(user, :read_epic_link_relation, epic)
    end

    def issuable
      request.issuable
    end
  end
end
