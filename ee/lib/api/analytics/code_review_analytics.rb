# frozen_string_literal: true

module API
  module Analytics
    class CodeReviewAnalytics < ::API::Base
      include PaginationParams

      feature_category :value_stream_management
      urgency :low

      helpers do
        def project
          @project ||= find_project!(params[:project_id])
        end

        def finder
          @finder ||= begin
            finder_options = {
              state: 'opened',
              project_id: project.id,
              sort: 'review_time_desc',
              attempt_project_search_optimizations: true
            }

            MergeRequestsFinder.new(current_user, declared_params.merge(finder_options))
          end
        end

        params :negatable_params do
          optional :label_name,
            type: Array[String],
            coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce,
            desc: 'Array of label names to filter by',
            documentation: { example: %w[feature bug] }
          optional :milestone_title,
            type: String,
            desc: 'Milestone title to filter by',
            documentation: { example: %w[1.6 1.7] }
        end
      end

      resource :analytics do
        desc 'List code review information about project' do
          success code: 200, model: EE::API::Entities::Analytics::CodeReview::MergeRequest
        end
        params do
          requires :project_id, type: Integer, desc: 'Project ID'
          use :negatable_params
          use :pagination
          optional :not, type: Hash do
            use :negatable_params
          end
        end
        get 'code_review' do
          authorize! :read_code_review_analytics, project

          merge_requests = paginate(finder.execute.with_code_review_api_entity_associations)

          present merge_requests,
            with: EE::API::Entities::Analytics::CodeReview::MergeRequest,
            current_user: current_user,
            issuable_metadata: Gitlab::IssuableMetadata.new(current_user, merge_requests).data
        end
      end
    end
  end
end
