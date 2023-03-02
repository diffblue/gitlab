# frozen_string_literal: true

# This class is reponsible for identifying whether a build run in a pipeline
# that is considered a community contribution to any GitLab projects.
#
# When a merge request pipeline from a fork targets a project from an enabled
# namespace, we consider it a community contribution.
#
# Since GitLab pipelines are very heavy in CI minutes consumption we don't want
# to impact community contributions. Instead we grant them a low cost factor
# that allows them to run pipelines with minimal CI minutes consumption.
#
module Gitlab
  module Ci
    module Minutes
      class GitlabContributionCostFactor
        include Gitlab::Utils::StrongMemoize

        # The max number of CI minutes that a top-level namespace can consume
        # in contributions to GitLab projects.
        MAX_SHARED_RUNNERS_DURATION_MINUTES = 300_000

        def initialize(project, merge_request)
          @project = project
          @merge_request = merge_request
        end

        def cost_factor
          return unless gitlab_contribution_cost_factor?

          # We want to guarantee that namespaces can only use
          # MAX_SHARED_RUNNERS_DURATION_MINUTES (pre-cost factor minutes)
          # for GitLab contributions, regardless of their plan.
          # In order to do that we can calculate the cost factor by adjusting it
          # based on the monthly quota.
          #
          # Example:
          # - 300,000 duration in minutes * 0.03333333333 cost factor = 10,000 CI minutes quota
          # - 10,000 CI minutes quota / 300,000 duration in minutes = 0.03333333333 cost factor
          minutes_quota.monthly.to_f / MAX_SHARED_RUNNERS_DURATION_MINUTES
        end

        private

        attr_reader :project, :merge_request

        def minutes_quota
          strong_memoize(:minutes_quota) do
            ::Ci::Minutes::Quota.new(project.root_namespace)
          end
        end

        def gitlab_contribution_cost_factor?
          merge_request &&
            gitlab_group_contribution? &&
            minutes_quota.enabled?
        end

        def gitlab_group_contribution?
          # only supports pipelines with a merge_request_event source
          merge_request.for_fork? &&
            merge_request_target_namespace &&
            gitlab_namespace?
        end

        def gitlab_namespace?
          ::Feature.enabled?(
            :ci_minimal_cost_factor_for_gitlab_namespaces,
            merge_request_target_namespace,
            type: :ops
          )
        end

        def merge_request_target_namespace
          strong_memoize(:merge_request_target_namespace) do
            target_project&.root_namespace
          end
        end

        def target_project
          strong_memoize(:target_project) do
            merge_request.target_project
          end
        end
      end
    end
  end
end
