# frozen_string_literal: true

module EE
  module Gitlab
    module QuickActions
      module EpicActions
        extend ActiveSupport::Concern
        include ::Gitlab::QuickActions::Dsl

        included do
          desc { _('Add child epic to an epic') }
          explanation do |epic_param|
            child_epic = extract_epic(epic_param)

            _("Adds %{epic_ref} as child epic.") % { epic_ref: child_epic.to_reference(quick_action_target) } if child_epic
          end
          types Epic
          condition { can_admin_relation? }
          params '<&epic | group&epic | Epic URL>'
          command :child_epic do |epic_param|
            child_epic = extract_epic(epic_param)
            child_error = validate_update(quick_action_target, child_epic, :child)

            @execution_message[:child_epic] =
              if child_error.present?
                child_error
              else
                @updates[:quick_action_assign_child_epic] = child_epic

                success_set_message(quick_action_target, child_epic, :child)
              end
          end

          desc { _('Remove child epic from an epic') }
          explanation do |epic_param|
            child_epic = extract_epic(epic_param)

            _("Removes %{epic_ref} from child epics.") % { epic_ref: child_epic.to_reference(quick_action_target) } if child_epic
          end
          types Epic
          condition { action_allowed_only_on_update? }
          params '<&epic | group&epic | Epic URL>'
          command :remove_child_epic do |epic_param|
            child_epic = extract_epic(epic_param)
            child_error = validate_removal(quick_action_target, child_epic, :child)

            @execution_message[:remove_child_epic] =
              if child_error.present?
                child_error
              else
                Epics::EpicLinks::DestroyService.new(child_epic, current_user).execute

                success_remove_message(quick_action_target, child_epic, :child)
              end
          end

          desc { _('Set parent epic to an epic') }
          explanation do |epic_param|
            parent_epic = extract_epic(epic_param)

            _("Sets %{epic_ref} as parent epic.") % { epic_ref: parent_epic.to_reference(quick_action_target) } if parent_epic
          end
          types Epic
          condition { can_admin_relation? }
          params '<&epic | group&epic | Epic URL>'
          command :parent_epic do |epic_param|
            parent_epic = extract_epic(epic_param)
            parent_error = validate_update(quick_action_target, parent_epic, :parent)

            @execution_message[:parent_epic] =
              if parent_error.present?
                parent_error
              else
                @updates[:quick_action_assign_to_parent_epic] = parent_epic

                success_set_message(quick_action_target, parent_epic, :parent)
              end
          end

          desc { _('Remove parent epic from an epic') }
          explanation do
            parent_epic = quick_action_target.parent

            _('Removes parent epic %{epic_ref}.') % { epic_ref: parent_epic.to_reference(quick_action_target) } if parent_epic
          end
          types Epic
          condition { action_allowed_only_on_update? }
          command :remove_parent_epic do
            parent_epic = quick_action_target.parent
            parent_error = validate_removal(quick_action_target, parent_epic, :parent)

            @execution_message[:remove_parent_epic] =
              if parent_error.present?
                parent_error
              else
                Epics::EpicLinks::DestroyService.new(quick_action_target, current_user).execute

                success_remove_message(quick_action_target, parent_epic, :parent)
              end
          end

          private

          def extract_epic(params)
            return if params.nil?

            extract_references(params, :epic).first
          end

          def can_admin_relation?(epic = quick_action_target)
            current_user.can?(:admin_epic_tree_relation, epic)
          end

          def action_allowed_only_on_update?
            quick_action_target.persisted? && can_admin_relation?
          end

          def epics_related?(epic, target_epic)
            epic.child?(target_epic.id) || target_epic.child?(epic.id)
          end

          def validate_update(target_epic, epic, type)
            return error_message(:does_not_exist, type) unless epic.present?
            return error_message(:already_related, type) if epics_related?(epic, target_epic)

            error_message(:no_permission, type) unless can_admin_relation?(epic)
          end

          def validate_removal(target_epic, epic, type)
            return error_message(:not_present, type) unless epic.present?
            return error_message(:does_not_exist, type) if type == :child && !target_epic.child?(epic.id)

            error_message(:no_permission, type) unless can_admin_relation?(epic)
          end

          def error_message(reason, relation)
            case reason
            when :does_not_exist
              _('%{relation_type} epic does not exist.') % { relation_type: relation.to_s.capitalize }
            when :not_present
              _('%{relation_type} epic is not present.') % { relation_type: relation.to_s.capitalize }
            when :already_related
              _('Given epic is already related to this epic.')
            when :no_permission
              _("You don't have sufficient permission to perform this action.")
            end
          end

          def success_set_message(target_epic, epic, relation)
            reference = epic.to_reference(target_epic)

            case relation
            when :child
              _('Added %{epic_ref} as a child epic.') % { epic_ref: reference }
            when :parent
              _('Set %{epic_ref} as the parent epic.') % { epic_ref: reference }
            end
          end

          def success_remove_message(target_epic, epic, relation)
            reference = epic.to_reference(target_epic)

            case relation
            when :child
              _('Removed %{epic_ref} from child epics.') % { epic_ref: reference }
            when :parent
              _('Removed parent epic %{epic_ref}.') % { epic_ref: reference }
            end
          end
        end
      end
    end
  end
end
