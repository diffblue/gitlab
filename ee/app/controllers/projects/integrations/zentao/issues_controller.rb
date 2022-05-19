# frozen_string_literal: true

module Projects
  module Integrations
    module Zentao
      class IssuesController < Projects::ApplicationController
        include RecordUserLastActivity

        before_action :check_feature_enabled!

        rescue_from ::Gitlab::Zentao::Client::Error, with: :render_error

        feature_category :integrations

        def index
          respond_to do |format|
            format.html
            format.json do
              render json: issues_json
            end
          end
        end

        def show
          @issue_json = issue_json
          respond_to do |format|
            format.html
            format.json do
              render json: @issue_json
            end
          end
        end

        private

        def query_params
          params.permit(:id, :page, :limit, :search, :sort, :state, labels: [])
        end

        def query
          ::Gitlab::Zentao::Query.new(project.zentao_integration, query_params)
        end

        def issue_json
          ::Integrations::ZentaoSerializers::IssueDetailSerializer.new
                                                                  .represent(query.issue, project: project)
        end

        def issues_json
          ::Integrations::ZentaoSerializers::IssueSerializer.new
                                                            .with_pagination(request, response)
                                                            .represent(query.issues, project: project)
        end

        def check_feature_enabled!
          return render_404 unless ::Integrations::Zentao.issues_license_available?(project) && project.zentao_integration&.active?
        end

        def render_error(exception)
          log_exception(exception)

          respond_to do |format|
            format.html do
              render action_name
            end
            format.json do
              render json: { errors: [s_('ZentaoIntegration|An error occurred while requesting data from the ZenTao service.')] },
                status: :bad_request
            end
          end
        end
      end
    end
  end
end
