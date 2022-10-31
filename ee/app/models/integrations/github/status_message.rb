# frozen_string_literal: true

module Integrations
  class Github
    class StatusMessage
      include Gitlab::Routing

      attr_reader :sha, :pipeline_id

      def initialize(project, service, params)
        @project = project
        @service = service
        @gitlab_status = params[:status]
        @detailed_status = params[:detailed_status]
        @pipeline_id = params[:id]
        @sha = params[:sha]
        @ref_name = params[:ref]
      end

      def context
        context_name.truncate(255)
      end

      def description
        "Pipeline #{@detailed_status} on GitLab".truncate(140)
      end

      def target_url
        project_pipeline_url(@project, @pipeline_id)
      end

      def status
        case @gitlab_status.to_s
        when 'created',
            'pending',
            'running',
            'manual'
          :pending
        when 'success',
            'skipped'
          :success
        when 'failed'
          :failure
        when 'canceled'
          :error
        end
      end

      def status_options
        {
          context: context,
          description: description,
          target_url: target_url
        }
      end

      def self.from_pipeline_data(project, service, data)
        new(project, service, data[:object_attributes])
      end

      private

      def context_name
        if @service.static_context?
          "ci/gitlab/#{::Gitlab.config.gitlab.host}#{context_suffix}"
        else
          "ci/gitlab/#{@ref_name}#{context_suffix}"
        end
      end

      def context_suffix
        pipeline = Ci::Pipeline.find(@pipeline_id)
        suffix = ""

        while pipeline.source_pipeline && pipeline.source_pipeline.source_project_id == pipeline.project_id
          suffix = "/#{pipeline.source_pipeline.source_job.name}#{suffix}"
          pipeline = pipeline.source_pipeline.source_pipeline
        end

        suffix
      end
    end
  end
end
