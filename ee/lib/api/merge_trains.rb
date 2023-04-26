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
        # Cars from many trains are mixed together in the response since no target_branch is provided.
        # Consider deprecating: https://gitlab.com/gitlab-org/gitlab/-/issues/406356
        desc 'Get all merge trains of a project' do
          detail 'This feature was introduced in GitLab 12.9'
          success code: 200, model: EE::API::Entities::MergeTrains::Car
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
          all_project_cars = ::MergeTrains::CarsFinder
            .new(user_project, current_user, declared_params(include_missing: false))
            .execute
            .preload_api_entities

          present paginate(all_project_cars), with: EE::API::Entities::MergeTrains::Car
        end

        resource ':target_branch' do
          desc 'Get the merge train for a project target branch' do
            detail 'This feature was introduced in Gitlab 15.6'
            success code: 200, model: EE::API::Entities::MergeTrains::Car
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
            merge_train = ::MergeTrains::CarsFinder
              .new(user_project, current_user, declared_params(include_missing: false))
              .execute
              .preload_api_entities

            present paginate(merge_train), with: EE::API::Entities::MergeTrains::Car
          end
        end

        resource 'merge_requests/:merge_request_iid', requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          desc 'Get the status of a merge request on a merge train' do
            detail 'This feature was introduced in Gitlab 15.6'
            success code: 200, model: EE::API::Entities::MergeTrains::Car
            failure [
              { code: 401, message: 'Unauthorized' },
              { code: 403, message: 'Forbidden' },
              { code: 404, message: 'Not found' }
            ]
          end
          get do
            train_car = find_project_merge_request(params[:merge_request_iid]).merge_train_car

            not_found!('Merge Train Merge Request') unless train_car

            present train_car, with: EE::API::Entities::MergeTrains::Car
          end
        end

        desc 'Add a merge request to a merge train' do
          detail 'This feature was introduced in GitLab 15.6'
          success [
            { code: 201, model: EE::API::Entities::MergeTrains::Car },
            { code: 202, model: EE::API::Entities::MergeTrains::Car }
          ]
          failure [
            { code: 400, message: 'Failed to merge' },
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' },
            { code: 409, message: 'Conflict' },
            { code: 403, message: 'Forbidden' }
          ]
        end
        params do
          optional :sha, type: String,
            desc: 'If present, then the SHA must match the HEAD of the source branch, otherwise the merge fails.'
          optional :squash, type: Grape::API::Boolean,
            desc: 'When true, the commits will be squashed into a single commit on merge'
          optional :when_pipeline_succeeds, type: Grape::API::Boolean,
            desc: 'When true, this merge request will be merged when the pipeline succeeds'
        end
        post 'merge_requests/:merge_request_iid', requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          merge_request = find_project_merge_request(params[:merge_request_iid])

          check_sha_param!(params, merge_request)

          response = ::MergeTrains::AddMergeRequestService.new(
            merge_request,
            current_user,
            params.slice(:sha, :squash, :when_pipeline_succeeds)
          ).execute

          if response.success?
            whole_merge_train = ::MergeTrains::CarsFinder
              .new(user_project, current_user, { target_branch: merge_request.target_branch })
              .execute
              .preload_api_entities

            if merge_request.merge_train_car
              status 201
            else
              status 202
            end

            present paginate(whole_merge_train), with: EE::API::Entities::MergeTrains::Car
          elsif response.reason == :forbidden
            unauthorized!
          else
            bad_request!(response.message)
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
