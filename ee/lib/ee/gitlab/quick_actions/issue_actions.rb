# frozen_string_literal: true

module EE
  module Gitlab
    module QuickActions
      module IssueActions
        extend ActiveSupport::Concern
        include ::Gitlab::QuickActions::Dsl

        included do
          desc { _('Add to epic') }
          explanation { _('Adds an issue to an epic.') }
          types Issue
          condition do
            quick_action_target.supports_epic? &&
              quick_action_target.project.group&.feature_available?(:epics) &&
              current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target)
          end
          params '<&epic | group&epic | Epic URL>'
          command :epic do |epic_param|
            epic = extract_epic(epic_param)
            issue = quick_action_target

            message =
              if epic && current_user.can?(:read_epic, epic)
                if issue&.epic == epic
                  _('Issue %{issue_reference} has already been added to epic %{epic_reference}.') %
                    { issue_reference: issue.to_reference, epic_reference: epic.to_reference }
                else
                  @updates[:epic] = epic
                  _('Added an issue to an epic.')
                end
              else
                _("This epic does not exist or you don't have sufficient permission.")
              end

            @execution_message[:epic] = message
          end

          desc { _('Remove from epic') }
          explanation { _('Removes an issue from an epic.') }
          execution_message { _('Removed an issue from an epic.') }
          types Issue
          condition do
            quick_action_target.persisted? &&
              quick_action_target.supports_epic? &&
              quick_action_target.project.group&.feature_available?(:epics) &&
              current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target)
          end
          command :remove_epic do
            @updates[:epic] = nil
          end

          desc { _('Promote issue to an epic') }
          explanation { _('Promote issue to an epic') }
          icon 'confidential'
          types Issue
          condition do
            quick_action_target.can_be_promoted_to_epic?(current_user)
          end
          command :promote do
            @updates[:promote_to_epic] = true

            @execution_message[:promote] = _('Promoted issue to an epic.')
          end

          desc { _('Set iteration') }
          explanation do |iteration|
            _("Sets the iteration to %{iteration_reference}.") % { iteration_reference: iteration.to_reference } if iteration
          end
          execution_message do |iteration|
            _("Set the iteration to %{iteration_reference}.") % { iteration_reference: iteration.to_reference } if iteration
          end
          params '*iteration:"iteration name" | *iteration:<ID>'
          types Issue
          condition do
            quick_action_target.supports_iterations? &&
              current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project) &&
              quick_action_target.project.group&.feature_available?(:iterations) &&
              find_iterations(project, state: 'opened').any?
          end
          parse_params do |iteration_param|
            extract_references(iteration_param, :iteration).first ||
              find_iterations(project, title: iteration_param.strip, state: 'opened').first
          end
          command :iteration do |iteration|
            @updates[:iteration] = iteration if iteration
          end

          desc { _('Remove iteration') }
          explanation do
            _("Removes %{iteration_reference} iteration.") % { iteration_reference: quick_action_target.iteration.to_reference(format: :name) }
          end
          execution_message do
            _("Removed %{iteration_reference} iteration.") % { iteration_reference: quick_action_target.iteration.to_reference(format: :name) }
          end
          types Issue
          condition do
            quick_action_target.supports_iterations? &&
              quick_action_target.persisted? &&
              quick_action_target.sprint_id? &&
              quick_action_target.project.group&.feature_available?(:iterations) &&
              current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project)
          end
          command :remove_iteration do
            @updates[:iteration] = nil
          end

          def extract_epic(params)
            return if params.nil?

            extract_references(params, :epic).first
          end

          def find_iterations(project, params = {})
            parent_params = { parent: project, include_ancestors: true }

            ::IterationsFinder.new(current_user, params.merge(parent_params)).execute
          end

          desc { _('Publish to status page') }
          explanation { _('Publishes this issue to the associated status page.') }
          types Issue
          condition do
            StatusPage::MarkForPublicationService.publishable?(project, current_user, quick_action_target)
          end
          command :publish do
            if ::Gitlab::StatusPage.mark_for_publication(project, current_user, quick_action_target).success?
              ::Gitlab::StatusPage.trigger_publish(project, current_user, quick_action_target, action: :init)
              @execution_message[:publish] = _('Issue published on status page.')
            else
              @execution_message[:publish] = _('Failed to publish issue on status page.')
            end
          end

          desc { _('Set health status') }
          explanation do |health_status|
            _("Sets health status to %{health_status}.") % { health_status: health_status } if health_status
          end

          params "<#{::Issue.health_statuses.keys.join('|')}>"
          types Issue
          condition do
            quick_action_target.supports_health_status? &&
              current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target)
          end
          parse_params do |health_status|
            find_health_status(health_status)
          end
          command :health_status do |health_status|
            if health_status
              @updates[:health_status] = health_status
              @execution_message[:health_status] = _("Set health status to %{health_status}.") % { health_status: health_status }
            end
          end

          desc { _('Clear health status') }
          explanation { _('Clears health status.') }
          execution_message { _('Cleared health status.') }
          types Issue
          condition do
            quick_action_target.persisted? &&
              quick_action_target.supports_health_status? &&
              quick_action_target.health_status &&
              current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target)
          end
          command :clear_health_status do
            @updates[:health_status] = nil
          end

          desc { _('Escalate this incident') }
          explanation { _('Starts escalations for this incident') }
          params '<policy name>'
          types Issue
          condition do
            current_user.can?(:update_escalation_status, quick_action_target) &&
            quick_action_target.persisted? &&
            quick_action_target.escalation_policies_available?
          end

          command :page do |escalation_policy_name|
            policy = quick_action_target.project.incident_management_escalation_policies.find_by_name(escalation_policy_name)
            if policy.nil?
              @execution_message[:page] = _("Policy '%{escalation_policy_name}' does not exist.") % { escalation_policy_name: escalation_policy_name }
            else
              issue = ::Issues::UpdateService
                .new(project: quick_action_target.project,
                      current_user: current_user,
                      params: {
                        escalation_status: { status: :triggered, policy: policy }
                      }
                    ).execute(quick_action_target)

              @execution_message[:page] =
                if issue.escalation_status.saved_change_to_updated_at?
                  _('Started escalation for this incident.')
                else
                  _("This incident is already escalated with '%{escalation_policy_name}'.") % { escalation_policy_name: escalation_policy_name }
                end
            end
          end
        end

        private

        def find_health_status(health_status_param)
          return unless health_status_param

          health_status_param = health_status_param.downcase
          health_statuses = ::Issue.health_statuses.keys.map(&:downcase)

          health_statuses.include?(health_status_param) && health_status_param
        end
      end
    end
  end
end
