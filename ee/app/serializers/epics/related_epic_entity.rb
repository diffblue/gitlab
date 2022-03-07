# frozen_string_literal: true

module Epics
  class RelatedEpicEntity < Grape::Entity
    include RequestAwareEntity

    expose :id, :confidential, :title, :state, :created_at, :closed_at

    expose :reference do |related_epic|
      related_epic.to_reference(request.issuable.group)
    end

    expose :path do |related_epic|
      group_epic_path(related_epic.group, related_epic)
    end

    expose :link_type do |related_epic|
      related_epic.epic_link_type
    end
  end
end
