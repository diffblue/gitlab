# frozen_string_literal: true

module Epics
  module EpicLinks
    class CreateService < IssuableLinks::CreateService
      def execute
        unless can?(current_user, :admin_epic_tree_relation, issuable)
          return error(issuables_not_found_message, 404)
        end

        if issuable.max_hierarchy_depth_achieved?
          return error("This epic cannot be added. One or more epics would "\
                       "exceed the maximum depth (#{Epic::MAX_HIERARCHY_DEPTH}) "\
                       "from its most distant ancestor.", 409)
        end

        if referenced_issuables.count == 1
          create_single_link
        else
          super
        end
      end

      private

      def create_single_link
        child_epic = referenced_issuables.first

        unless can?(current_user, :read_epic, child_epic)
          return error(issuables_not_found_message, 404)
        end

        previous_parent_epic = child_epic.parent

        if linkable_epic?(child_epic) && set_child_epic(child_epic)
          create_notes(child_epic, previous_parent_epic)
          success(created_references: [child_epic])
        else
          error(child_epic.errors.map(&:message).to_sentence, 409)
        end
      end

      def affected_epics(epics)
        [issuable, epics].flatten.uniq
      end

      def relate_issuables(referenced_epic)
        affected_epics = [issuable]
        previous_parent_epic = referenced_epic.parent

        affected_epics << referenced_epic if previous_parent_epic

        if set_child_epic(referenced_epic)
          create_notes(referenced_epic, previous_parent_epic)
        end

        referenced_epic
      end

      def create_notes(referenced_epic, previous_parent_epic)
        SystemNoteService.change_epics_relation(issuable, referenced_epic, current_user, 'relate_epic')

        return unless previous_parent_epic
        return if previous_parent_epic == issuable

        SystemNoteService.move_child_epic_to_new_parent(
          previous_parent_epic: previous_parent_epic,
          child_epic: referenced_epic,
          new_parent_epic: issuable,
          user: current_user
        )
      end

      def set_child_epic(child_epic)
        child_epic.parent = issuable
        child_epic.move_to_start
        child_epic.save
      end

      def linkable_issuables(epics)
        @linkable_issuables ||= epics.select do |epic|
          linkable_epic?(epic)
        end
      end

      def linkable_epic?(epic)
        can_link_epic?(epic) && epic.valid_parent?(parent_epic: issuable)
      end

      def references(extractor)
        extractor.epics
      end

      def extractor_context
        { group: issuable.group }
      end

      def previous_related_issuables
        issuable.children.to_a
      end

      def target_issuable_type
        :epic
      end

      def can_link_epic?(epic)
        return true if issuable.group == epic.group
        return true if can?(current_user, :admin_epic_tree_relation, epic)

        epic.errors.add(:parent, _("This epic cannot be added. You don't have access to perform this action."))

        false
      end
    end
  end
end
