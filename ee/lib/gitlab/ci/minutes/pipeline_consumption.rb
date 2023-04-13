# frozen_string_literal: true

module Gitlab
  module Ci
    module Minutes
      class PipelineConsumption
        def initialize(pipeline)
          @pipeline = pipeline
        end

        def amount
          builds_by_runner_matcher.sum do |runner_matcher, builds|
            ::Gitlab::Ci::Minutes::Consumption.new(
              pipeline: pipeline,
              runner_matcher: runner_matcher,
              duration: total_duration(builds)).amount
          end.round(2)
        end

        private

        attr_reader :pipeline

        def total_duration(builds)
          builds.sum { |build| build.duration || 0 }
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def builds_by_runner_matcher
          pipeline.builds.complete
            .joins(:runner).preload(:runner)
            .merge(::Ci::Runner.instance_type)
            .group_by { |build| build.runner.runner_matcher }
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
