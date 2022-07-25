# frozen_string_literal: true

module Ci
  class TriggerDownstreamSubscriptionService < ::BaseService
    def execute(pipeline)
      subscriptions(pipeline).each do |subscription|
        # Subscription's author was introduced afterwards. When not set we default
        # to the downstream project's creator.
        ::Ci::CreatePipelineService.new(
          subscription.downstream_project,
          (subscription.author || subscription.downstream_project.creator),
          ref: subscription.downstream_project.default_branch
        ).execute(:pipeline) do |downstream_pipeline|
          downstream_pipeline.build_source_project(source_project: pipeline.project)
        end
      end
    end

    private

    def subscriptions(pipeline)
      pipeline.project.downstream_project_subscriptions.with_downstream_and_author
    end
  end
end
