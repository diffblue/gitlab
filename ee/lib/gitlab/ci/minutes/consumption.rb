# frozen_string_literal: true

module Gitlab
  module Ci
    module Minutes
      # Calculate the consumption of CI minutes based on a cost factor
      # assigned to the involved Runner.
      # The amount returned is a float so that internally we could track
      # an accurate usage of minutes/credits.
      class Consumption
        include Gitlab::Utils::StrongMemoize

        def initialize(pipeline:, runner_matcher:, duration:)
          @pipeline = pipeline
          @runner_matcher = runner_matcher
          @duration = duration
        end

        def amount
          @amount ||= (duration.to_f / 60 * cost_factor).round(2)
        end

        private

        attr_reader :pipeline, :runner_matcher, :duration

        def cost_factor
          gitlab_cost_factor_applies = !!(
            runner_cost_factor > 0 &&
            gitlab_contribution_cost_factor
          )

          factor = if gitlab_cost_factor_applies
                     gitlab_contribution_cost_factor
                   else
                     runner_cost_factor
                   end

          log_cost_factor(factor, gitlab_cost_factor_applies)

          factor
        end

        def log_cost_factor(factor, gitlab_cost_factor_applies)
          Gitlab::AppLogger.info(
            cost_factor: factor,
            project_path: pipeline.project.full_path,
            pipeline_id: pipeline.id,
            class: self.class.name,
            gitlab_cost_factor_applied: gitlab_cost_factor_applies
          )
        end

        def runner_cost_factor
          ::Gitlab::Ci::Minutes::CostFactor.new(runner_matcher).for_project(pipeline.project)
        end
        strong_memoize_attr :runner_cost_factor

        def gitlab_contribution_cost_factor
          ::Gitlab::Ci::Minutes::GitlabContributionCostFactor
            .new(pipeline.project, pipeline.merge_request)
            .cost_factor
        end
        strong_memoize_attr :gitlab_contribution_cost_factor
      end
    end
  end
end
