# frozen_string_literal: true

module EE
  module FormHelper
    # Overwritten
    def reviewers_dropdown_options_for_suggested_reviewers
      suggested_reviewers_help_path = help_page_path(
        'user/project/merge_requests/reviews/index',
        anchor: 'suggested-reviewers'
      )

      {
        show_suggested: true,
        suggested_reviewers_help_path: suggested_reviewers_help_path,
        suggested_reviewers_header: _('Suggestion(s)'),
        all_members_header: _('All project members')
      }
    end

    def issue_supports_multiple_assignees?
      current_board_parent.feature_available?(:multiple_issue_assignees)
    end

    def merge_request_supports_multiple_assignees?
      @merge_request&.allows_multiple_assignees?
    end

    def merge_request_supports_multiple_reviewers?
      @merge_request&.allows_multiple_reviewers?
    end
  end
end
