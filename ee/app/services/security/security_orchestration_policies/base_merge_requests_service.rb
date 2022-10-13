# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class BaseMergeRequestsService
      def initialize(project:)
        @project = project
      end

      def each_open_merge_request
        related_merge_requests.each_batch do |mr_batch|
          mr_batch.each do |merge_request|
            yield merge_request
          end
        end
      end

      private

      def related_merge_requests
        @project.merge_requests.opened
      end
    end
  end
end
