# frozen_string_literal: true

module Projects
  module Security
    class NetworkPoliciesController < Projects::ApplicationController
      include SecurityAndCompliancePermissions

      POLLING_INTERVAL = 5_000

      before_action :authorize_read_threat_monitoring!
      before_action :set_polling_interval, only: [:summary]

      # This controller is being removed in https://gitlab.com/gitlab-org/gitlab/-/issues/352285
      feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned

      def summary
        return not_found unless environment.has_metrics?

        adapter = environment.prometheus_adapter
        return not_found unless adapter.can_query?

        result = adapter.query(
          :packet_flow, environment.deployment_namespace,
          params[:interval] || "minute",
          parse_time(params[:from], 1.hour.ago).to_s,
          parse_time(params[:to], Time.current).to_s
        )

        respond_to do |format|
          format.json do
            if result
              status = result[:success] ? :ok : :bad_request
              render status: status, json: result[:data]
            else
              render status: :accepted, json: {}
            end
          end
        end
      end

      def index
        response = NetworkPolicies::ResourcesService.new(project: project, environment_id: params[:environment_id]).execute
        respond_with_service_response(response)
      end

      def create
        response = NetworkPolicies::DeployResourceService.new(
          manifest: params[:manifest],
          environment: environment
        ).execute

        respond_with_service_response(response)
      end

      def update
        response = NetworkPolicies::DeployResourceService.new(
          resource_name: params[:id],
          manifest: params[:manifest],
          environment: environment,
          enabled: params[:enabled]
        ).execute

        respond_with_service_response(response)
      end

      def destroy
        response = NetworkPolicies::DeleteResourceService.new(
          resource_name: params[:id],
          manifest: params[:manifest],
          environment: environment
        ).execute

        respond_with_service_response(response)
      end

      private

      def parse_time(params, fallback)
        Time.zone.parse(params) || fallback
      rescue StandardError
        fallback
      end

      def environment
        @environment ||= project.environments.find(params[:environment_id])
      end

      def set_polling_interval
        Gitlab::PollingInterval.set_header(response, interval: POLLING_INTERVAL)
      end

      def authorize_read_threat_monitoring!
        render_403 unless can?(current_user, :read_threat_monitoring, project)
      end

      def respond_with_service_response(response)
        payload = response.success? ? response.payload : { payload: response.payload, error: response.message }
        respond_to do |format|
          format.json do
            render status: response.http_status, json: payload
          end
        end
      end
    end
  end
end
