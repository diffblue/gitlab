# frozen_string_literal: true

module EE
  module IssueLink
    extend ActiveSupport::Concern

    prepended do
      # TODO - Move this to EE::IssuableLink when `blocking_epics_count` is added to epics table.
      # More information at https://gitlab.com/gitlab-org/gitlab/-/issues/353789.
      after_create :refresh_blocking_issue_cache
      after_destroy :refresh_blocking_issue_cache
    end

    private

    def blocking_issue
      source if link_type == ::IssueLink::TYPE_BLOCKS
    end

    def refresh_blocking_issue_cache
      blocking_issue&.update_blocking_issues_count!
    end
  end
end
