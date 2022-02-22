# frozen_string_literal: true

module EE
  module Boards
    module IssuesController
      extend ::Gitlab::Utils::Override

      override :serializer_options
      def serializer_options(issues)
        super.merge(blocked_issue_ids: ::IssueLink.blocked_issuable_ids(issues.map(&:id)))
      end
    end
  end
end
