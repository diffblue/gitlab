# frozen_string_literal: true

module Notes
  class CreateVisualReviewService < BaseService
    attr_reader :merge_request, :current_user, :body, :position

    def initialize(merge_request, current_user, body:, position: nil)
      @merge_request = merge_request
      @current_user = current_user
      @body = body
      @position = position
    end

    def execute
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :create_visual_review_note, merge_request)

      Notes::CreateService.new(merge_request.project, User.visual_review_bot, note_params).execute
    end

    private

    def note_params
      {
        note: note_body(current_user, body),
        position: position,
        type: 'DiscussionNote',
        noteable_type: 'MergeRequest',
        noteable_id: merge_request.id
      }
    end

    def note_body(user, body)
      if user && body.present?
        "**Feedback from @#{user.username} (#{user.email})**\n\n#{body}"
      else
        body
      end
    end
  end
end
