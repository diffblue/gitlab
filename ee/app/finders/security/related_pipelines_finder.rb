# frozen_string_literal: true

# Security::RelatedPipelinesFinder
#
# This finder returns the IDs of latest completed pipelines per given
# sources matching the SHA as the given pipeline. If the pipeline is a
# merged_request_pipeline, the source SHA of the pipeline is used to
# find the related pipelines.
#
# Arguments:
#   pipeline - pipeline for which the related pipelines should be returned
#   params:
#     sources:    Array<String>
module Security
  class RelatedPipelinesFinder
    attr_reader :pipeline, :params

    def initialize(pipeline, params = {})
      @pipeline = pipeline
      @params = params
    end

    def execute
      pipelines = latest_completed_pipelines_matching_sha
      pipelines = pipelines.with_pipeline_source(params[:sources]) if params[:sources].present?

      # Using map here as `pluck` would not work due to usage of `SELECT max(id)`
      pipelines.map(&:id)
    end

    private

    delegate :project, to: :pipeline

    def all_pipelines
      project.all_pipelines
    end

    def latest_completed_pipelines_matching_sha
      # merged_result_pipeline should include itself and the pipelines with source_sha
      sha = pipeline.merged_result_pipeline? ? [pipeline.source_sha, pipeline.sha] : pipeline.sha
      all_pipelines.latest_completed_pipeline_ids_per_source(sha)
    end
  end
end
