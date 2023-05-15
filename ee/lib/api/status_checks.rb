# frozen_string_literal: true

module API
  class StatusChecks < ::API::Base
    include PaginationParams

    feature_category :compliance_management

    before do
      authenticate!
      check_feature_enabled!
    end

    helpers do
      def check_feature_enabled!
        unauthorized! unless user_project.licensed_feature_available?(:external_status_checks)
      end
    end

    resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      segment ':id/external_status_checks' do
        desc 'Create external status check' do
          success code: 201, model: ::API::Entities::ExternalStatusCheck
        end
        params do
          requires :name, type: String, desc: 'Display name of external status check', documentation: { example: 'QA' }
          requires :external_url,
            type: String,
            desc: 'URL of external status check resource',
            documentation: { example: 'https://www.example.com' }
          optional :protected_branch_ids,
            type: Array[Integer],
            coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce,
            desc: 'IDs of protected branches to scope the rule by', documentation: { is_array: true }
        end
        post do
          service = ::ExternalStatusChecks::CreateService.new(
            container: user_project,
            current_user: current_user,
            params: declared_params(include_missing: false)
          ).execute

          if service.success?
            present service.payload[:rule], with: ::API::Entities::ExternalStatusCheck
          else
            render_api_error!(service.payload[:errors], service.http_status)
          end
        end
        desc 'Get project external status checks' do
          success ::API::Entities::ExternalStatusCheck
          is_array true
        end
        params do
          use :pagination
        end
        get do
          unauthorized! unless current_user.can?(:admin_project, user_project)

          present paginate(user_project.external_status_checks), with: ::API::Entities::ExternalStatusCheck
        end

        segment ':check_id' do
          desc 'Update external status check' do
            success ::API::Entities::ExternalStatusCheck
          end
          params do
            requires :check_id,
              type: Integer,
              desc: 'ID of an external status check',
              documentation: { example: 1 }
            optional :name, type: String, desc: 'Display name of external status check', documentation: { example: 'QA' }
            optional :external_url,
              type: String,
              desc: 'URL of external status check resource',
              documentation: { example: 'https://www.example.com' }
            optional :protected_branch_ids,
              type: Array[Integer],
              coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce,
              desc: 'IDs of protected branches to scope the rule by', documentation: { is_array: true }
          end
          put do
            service = ::ExternalStatusChecks::UpdateService.new(
              container: user_project,
              current_user: current_user,
              params: declared_params(include_missing: false)
            ).execute

            if service.success?
              present service.payload[:rule], with: ::API::Entities::ExternalStatusCheck
            else
              render_api_error!(service.payload[:errors], service.http_status)
            end
          end

          desc 'Delete external status check' do
            success code: 204
          end
          params do
            requires :check_id, type: Integer, desc: 'ID of an external status check'
          end
          delete do
            external_status_check = user_project.external_status_checks.find(params[:check_id])

            destroy_conditionally!(external_status_check) do |external_status_check|
              ::ExternalStatusChecks::DestroyService.new(
                container: user_project,
                current_user: current_user
              ).execute(external_status_check)
            end
          end
        end
      end

      segment ':id/merge_requests/:merge_request_iid' do
        desc 'Set status of an external status check' do
          success Entities::MergeRequests::StatusCheckResponse
        end
        params do
          requires :id, type: String, desc: 'ID of a project', documentation: { example: '1' }
          requires :merge_request_iid,
            type: Integer,
            desc: 'IID of a merge request',
            documentation: { example: 1 }
          requires :external_status_check_id,
            type: Integer,
            desc: 'ID of an external status check',
            documentation: { example: 1 }
          requires :sha,
            type: String,
            desc: 'SHA at HEAD of the source branch',
            documentation: { example: '5957a570eee0ac4580ec027fb874ad7514d1e576' }
          requires :status,
            type: String,
            desc: 'Set to passed to pass the check or failed to fail it',
            values: %w(passed failed),
            documentation: { example: 'passed' }
        end
        post 'status_check_responses' do
          merge_request = find_merge_request_with_access(params[:merge_request_iid], :approve_merge_request)

          status_check = merge_request.project.external_status_checks.find(params[:external_status_check_id])

          check_sha_param!(params, merge_request)

          not_found! unless current_user.can?(:provide_status_check_response, merge_request)

          approval = merge_request.status_check_responses.create!(external_status_check: status_check, sha: params[:sha], status: params[:status])

          present(approval, with: Entities::MergeRequests::StatusCheckResponse)
        end

        segment 'status_checks' do
          desc 'List status checks for a merge request' do
            success Entities::MergeRequests::StatusCheck
            is_array true
          end
          get do
            merge_request = find_merge_request_with_access(params[:merge_request_iid], :approve_merge_request)

            ::Gitlab::PollingInterval.set_api_header(self, interval: 10_000)
            present(paginate(user_project.external_status_checks.applicable_to_branch(merge_request.target_branch)), with: Entities::MergeRequests::StatusCheck, merge_request: merge_request, sha: merge_request.diff_head_sha, current_user: current_user)
          end

          desc 'Retry failed external status check' do
            success code: 202
          end
          params do
            requires :id, type: String, desc: 'ID of a project', documentation: { example: '1' }
            requires :merge_request_iid,
              type: Integer,
              desc: 'IID of a merge request',
              documentation: { example: 1 }
            requires :external_status_check_id, type: Integer, desc: 'ID of a failed external status check'
          end
          post ':external_status_check_id/retry' do
            merge_request = find_merge_request_with_access(params[:merge_request_iid], :approve_merge_request)

            not_found! unless current_user.can?(:retry_failed_status_checks, merge_request)

            status_check = merge_request.project.external_status_checks.find(params[:external_status_check_id])

            if status_check.failed?(merge_request)
              data = merge_request.to_hook_data(current_user)
              status_check.async_execute(data)
              accepted!
            else
              unprocessable_entity!("External status check must be failed")
            end
          end
        end
      end
    end
  end
end
