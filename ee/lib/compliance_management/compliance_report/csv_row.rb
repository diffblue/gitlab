# frozen_string_literal: true

module ComplianceManagement
  module ComplianceReport
    class CsvRow
      def initialize(commit, user, from, to, options = {})
        @user = user
        @commit = commit
        @from = from
        @to = to
        @merge_request = options[:merge_request]
      end

      attr_reader :from, :to, :commit, :user, :merge_request

      def sha
        commit&.sha
      end

      def author
        commit&.author&.name || merge_request&.author&.name
      end

      def committer
        commit&.committer_name
      end

      def committed_at
        commit&.timestamp
      end

      def group
        commit&.project&.namespace&.name || merge_request&.project&.group&.name
      end

      def project
        commit&.project&.name || merge_request&.project&.name
      end

      def merge_commit
        merge_request&.merge_commit_sha
      end

      def merge_request_id
        merge_request&.id
      end

      def merged_by
        merge_request&.metrics&.merged_by&.name
      end

      def merged_at
        merge_request&.merged_at
      end

      def pipeline
        merge_request&.metrics&.pipeline_id
      end

      def approvers
        merge_request&.approved_by_users&.map(&:name)&.sort&.join(" | ")
      end
    end
  end
end
