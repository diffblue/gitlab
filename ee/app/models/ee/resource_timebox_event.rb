# frozen_string_literal: true

module EE
  module ResourceTimeboxEvent
    extend ::Gitlab::Utils::Override

    private

    override :issue_usage_metrics
    def issue_usage_metrics
      return unless for_issue?

      case self
      when ResourceIterationEvent
        ::Gitlab::UsageDataCounters::IssueActivityUniqueCounter
          .track_issue_iteration_changed_action(author: user, project: issue.project)
      else
        super
      end
    end
  end
end
