# frozen_string_literal: true

module Deployments
  class ApprovalWorker
    include ApplicationWorker

    data_consistency :delayed
    sidekiq_options retry: 3

    queue_namespace :deployment
    feature_category :continuous_delivery

    idempotent!

    def perform(deployment_id, params = {})
      params = params.with_indifferent_access

      Deployment.find_by_id(deployment_id).try do |deployment|
        user = User.find_by_id(params[:user_id])
        result = ::Deployments::ApprovalService.new(deployment.project, user).execute(deployment, params[:status])

        unless result[:status] == :success
          log_extra_metadata_on_done(:error_message, result[:message])
          log_extra_metadata_on_done(:deployment_id, deployment_id)
          log_extra_metadata_on_done(:user_id, params[:user_id])
          log_extra_metadata_on_done(:status, params[:status])
        end
      end
    end
  end
end
