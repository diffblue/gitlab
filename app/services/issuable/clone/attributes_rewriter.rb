# frozen_string_literal: true

module Issuable
  module Clone
    class AttributesRewriter < ::Issuable::Clone::BaseService
      def initialize(current_user, original_entity, new_entity)
        @current_user = current_user
        @original_entity = original_entity
        @new_entity = new_entity
      end

      def execute
        update_attributes = { labels: cloneable_labels }

        milestone = matching_milestone(original_entity.milestone&.title)
        update_attributes[:milestone] = milestone if milestone.present?

        new_entity.update(update_attributes)
      end

      private

      def cloneable_labels
        params = {
          project_id: new_entity.project&.id,
          group_id: group&.id,
          title: original_entity.labels.select(:title),
          include_ancestor_groups: true
        }

        params[:only_group_labels] = true if new_parent.is_a?(Group)

        LabelsFinder.new(current_user, params).execute
      end

      def matching_milestone(title)
        return if title.blank? || !new_entity.supports_milestone?

        params = { title: title, project_ids: new_entity.project&.id, group_ids: group&.id }

        milestones = MilestonesFinder.new(params).execute
        milestones.first
      end
    end
  end
end
