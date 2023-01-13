# frozen_string_literal: true

module API
  class EpicIssues < ::API::Base
    include PaginationParams

    feature_category :portfolio_management
    urgency :low

    before do
      authenticate!
      authorize_epics_feature!
    end

    helpers ::API::Helpers::EpicsHelpers

    helpers do
      def link
        @link ||= epic.epic_issues.find(params[:epic_issue_id])
      end

      def related_issues(epic)
        IssuesFinder.new(current_user, { epic_id: epic.id }).execute
          .with_api_entity_associations
          .sorted_by_epic_position
      end

      def authorize_can_assign_to_epic!(issue)
        forbidden! unless can?(current_user, :read_epic, epic) && can?(current_user, :admin_issue_relation, issue)
      end
    end

    params do
      requires :id, types: [Integer, String], desc: 'The ID or URL-encoded path of the group owned by the authenticated user', documentation: { example: '1' }
    end

    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Update epic-issue association' do
        detail 'Updates an epic-issue association'
        is_array true
        success EE::API::Entities::EpicIssue
        failure [
          { code: 400, message: 'Issue could not be moved!' },
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[epic_issues]
      end
      params do
        requires :epic_iid, types: [Integer, String], desc: 'The internal ID of the epic', documentation: { example: 5 }
        requires :epic_issue_id, types: [Integer, String], desc: 'The ID of the epic-issue association to update', documentation: { example: 11 }
        optional :move_before_id, types: [Integer, String], desc: 'The ID of the epic-issue association that should be positioned before the actual issue', documentation: { example: 20 }
        optional :move_after_id, types: [Integer, String], desc: 'The ID of the epic-issue association that should be positioned after the actual issue', documentation: { example: 25 }
        use :pagination
      end
      put ':id/(-/)epics/:epic_iid/issues/:epic_issue_id' do
        authorize_can_assign_to_epic!(link.issue)

        update_params = {
          move_before_id: params[:move_before_id],
          move_after_id: params[:move_after_id]
        }

        result = ::EpicIssues::UpdateService.new(link, current_user, update_params).execute

        if result
          present paginate(related_issues(epic)),
            with: EE::API::Entities::EpicIssue,
            current_user: current_user
        else
          render_api_error!({ error: "Issue could not be moved!" }, 400)
        end
      end

      [':id/epics/:epic_iid/issues', ':id/-/epics/:epic_iid/issues'].each do |path|
        desc 'List issues for an epic' do
          detail 'Gets all issues that are assigned to an epic and the authenticated user has access to'
          is_array true
          success EE::API::Entities::EpicIssue
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[epic_issues]
        end
        params do
          requires :epic_iid, types: [Integer, String], desc: 'The internal ID of the epic', documentation: { example: 5 }
          use :pagination
        end
        get path do
          authorize_can_read!

          present paginate(related_issues(epic)),
            with: EE::API::Entities::EpicIssue,
            current_user: current_user,
            include_subscribed: false
        end
      end

      desc 'Assign an issue to the epic' do
        detail 'Creates an epic-issue association. If the issue in question belongs to another epic it is unassigned from that epic'
        success EE::API::Entities::EpicIssueLink
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'No matching issue found' },
          { code: 409, message: 'Issue already assigned' }
        ]
        tags %w[epic_issues]
      end
      params do
        requires :epic_iid, types: [Integer, String], desc: 'The internal ID of the epic', documentation: { example: 5 }
        requires :issue_id, types: [Integer, String], desc: 'The ID of the issue', documentation: { example: 55 }
      end
      # rubocop: disable CodeReuse/ActiveRecord
      post ':id/(-/)epics/:epic_iid/issues/:issue_id' do
        authorize_can_read!
        issue = Issue.find(params[:issue_id])
        authorize!(:admin_issue_relation, issue)

        create_params = { target_issuable: issue }

        result = ::EpicIssues::CreateService.new(epic, current_user, create_params).execute

        if result[:status] == :success
          epic_issue_link = EpicIssue.find_by!(epic: epic, issue: issue)

          present epic_issue_link, with: EE::API::Entities::EpicIssueLink
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Remove an issue from the epic' do
        detail 'Removes an epic-issue association'
        success code: 200, model: EE::API::Entities::EpicIssueLink
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[epic_issues]
      end
      params do
        requires :epic_iid, types: [Integer, String], desc: 'The internal ID of the epic', documentation: { example: 5 }
        requires :epic_issue_id, types: [Integer, String], desc: 'The ID of the association', documentation: { example: 11 }
      end
      delete ':id/(-/)epics/:epic_iid/issues/:epic_issue_id' do
        authorize_can_assign_to_epic!(link.issue)
        result = ::EpicIssues::DestroyService.new(link, current_user).execute

        if result[:status] == :success
          present link, with: EE::API::Entities::EpicIssueLink
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end
    end
  end
end
