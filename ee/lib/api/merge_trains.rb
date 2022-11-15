# frozen_string_literal: true

module API
  class MergeTrains < ::API::Base
    include PaginationParams

    feature_category :continuous_integration
    urgency :low

    before do
      authorize_read_merge_trains!
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project',
                    documentation: { example: 11 }
    end
    resource 'projects/:id', requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      resource :merge_trains do
        desc 'Get all merge trains of a project' do
          detail 'This feature was introduced in GitLab 12.9'
          success code: 200, model: EE::API::Entities::MergeTrain
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          is_array true
        end
        params do
          optional :scope, type: String, desc: 'The scope of merge trains', values: %w[active complete],
                           documentation: { example: 'active' }
          optional :sort,
            type: String, desc: 'Sort by asc (ascending) or desc (descending)', values: %w[asc desc], default: 'desc'
          use :pagination
        end
        get do
          merge_trains = ::MergeTrainsFinder
            .new(user_project, current_user, declared_params(include_missing: false))
            .execute
            .preload_api_entities

          present paginate(merge_trains), with: EE::API::Entities::MergeTrain
        end

        resource ':target_branch' do
          desc 'Get the merge train for a project target branch' do
            detail 'This feature was introduced in Gitlab 15.6'
            success code: 200, model: EE::API::Entities::MergeTrain
            failure [
              { code: 401, message: 'Unauthorized' },
              { code: 403, message: 'Forbidden' },
              { code: 404, message: 'Not found' }
            ]
            is_array true
          end
          params do
            requires :target_branch, type: String, desc: 'The target branch of the merge request',
                                     documentation: { example: 'main' }
            optional :scope, type: String, desc: 'The scope of merge trains', values: %w[active complete],
                             documentation: { example: 'active' }
            optional :sort,
              type: String, desc: 'Sort by asc (ascending) or desc (descending)', values: %w[asc desc], default: 'desc'
            use :pagination
          end
          get do
            merge_train = ::MergeTrainsFinder
              .new(user_project, current_user, declared_params(include_missing: false))
              .execute
              .preload_api_entities

            present paginate(merge_train), with: EE::API::Entities::MergeTrain
          end
        end
      end
    end

    helpers do
      def authorize_read_merge_trains!
        authorize! :read_merge_train, user_project
      end
    end
  end
end
