# frozen_string_literal: true

module Projects
  module Security
    class ScannedResourcesController < ::Projects::ApplicationController
      include SecurityAndCompliancePermissions

      before_action :authorize_read_vulnerability!
      before_action :scanned_resources

      feature_category :dynamic_application_security_testing
      urgency :low

      def index
        respond_to do |format|
          format.csv do
            send_data(
              render_csv,
              type: 'text/csv; charset=utf-8'
            )
          end
        end
      end

      private

      def scanned_resources
        pipeline = project.all_pipelines.find(pipeline_id)
        @scanned_resources = pipeline&.security_reports&.reports&.fetch('dast', nil)&.scanned_resources

        return if @scanned_resources

        render_404
      end

      def render_csv
        CsvBuilders::SingleBatch.new(
          @scanned_resources,
          {
            'Method': 'request_method',
            'Scheme': 'url_scheme',
            'Host': 'url_host',
            'Port': 'url_port',
            'Path': 'url_path',
            'Query String': 'url_query'
          }
        ).render
      end

      def pipeline_id
        params.require(:pipeline_id)
      end

      def authorize_read_vulnerability!
        return if can?(current_user, :read_security_resource, project)

        render_404
      end
    end
  end
end
