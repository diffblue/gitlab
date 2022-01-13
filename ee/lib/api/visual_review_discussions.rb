# frozen_string_literal: true

module API
  class VisualReviewDiscussions < ::API::Base
    include PaginationParams
    helpers ::API::Helpers::NotesHelpers
    helpers ::RendersNotes

    feature_category :review_apps

    params do
      requires :id, type: String, desc: "The ID of a Project"
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Create a new merge request discussion from visual review without authentication' do
        success Entities::Discussion
      end
      params do
        requires :merge_request_iid, types: [Integer, String], desc: 'The IID of the noteable'
        requires :body, type: String, desc: 'The content of a note'
        optional :position, type: Hash do
          requires :base_sha, type: String, desc: 'Base commit SHA in the source branch'
          requires :start_sha, type: String, desc: 'SHA referencing commit in target branch'
          requires :head_sha, type: String, desc: 'SHA referencing HEAD of this merge request'
          requires :position_type, type: String, desc: 'Type of the position reference', values: %w(text image)
          optional :new_path, type: String, desc: 'File path after change'
          optional :new_line, type: Integer, desc: 'Line number after change'
          optional :old_path, type: String, desc: 'File path before change'
          optional :old_line, type: Integer, desc: 'Line number before change'
          optional :width, type: Integer, desc: 'Width of the image'
          optional :height, type: Integer, desc: 'Height of the image'
          optional :x, type: Integer, desc: 'X coordinate in the image'
          optional :y, type: Integer, desc: 'Y coordinate in the image'
        end
      end
      post ":id/merge_requests/:merge_request_iid/visual_review_discussions" do
        unless Feature.enabled?(:anonymous_visual_review_feedback)
          forbidden!('Anonymous visual review feedback is disabled')
        end

        merge_request = find_merge_request(params[:merge_request_iid])

        note = ::Notes::CreateVisualReviewService.new(
          merge_request,
          current_user,
          body: params[:body],
          position: params[:position]
        ).execute

        if note.valid?
          present note.discussion, with: Entities::Discussion
        else
          bad_request!("Note #{note.errors.messages}")
        end
      end
    end
  end
end
