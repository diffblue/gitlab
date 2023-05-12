# frozen_string_literal: true

module Analytics
  module CodeReviewHelper
    def code_review_app_data(project)
      {
        project_id: project.id,
        project_path: project_path(project),
        new_merge_request_url: merge_request_source_project_for_project(project) ? namespace_project_new_merge_request_path(project.namespace) : nil,
        empty_state_svg_path: image_path('illustrations/empty-state/empty-merge-requests-md.svg'),
        milestone_path: project_milestones_path(project),
        labels_path: project_labels_path(project)
      }
    end
  end
end
