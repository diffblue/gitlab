# frozen_string_literal: true

module EE
  module API
    module Deployments
      extend ActiveSupport::Concern

      prepended do
        params do
          requires :id, type: String, desc: 'The project ID'
        end
        resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          desc 'Approve or reject a blocked deployment' do
            detail 'This feature was introduced in GitLab 14.8.'
            success ::API::Entities::Deployments::Approval
          end
          params do
            requires :deployment_id, type: String, desc: 'The Deployment ID'
            requires :status, type: String, values: ::Deployments::Approval.statuses.keys
          end
          post ':id/deployments/:deployment_id/approval' do
            deployment = user_project.deployments.find(params[:deployment_id])

            result = ::Deployments::ApprovalService.new(user_project, current_user)
                                                   .execute(deployment, params[:status])

            if result[:status] == :success
              present(result[:approval], with: ::API::Entities::Deployments::Approval, current_user: current_user)
            else
              render_api_error!(result[:message], 400)
            end
          end
        end
      end
    end
  end
end
