# frozen_string_literal: true

module Ci
  module Minutes
    class UpdateProjectAndNamespaceUsageWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker
      include PipelineBackgroundQueue

      urgency :low
      data_consistency :always # primarily performs writes

      def perform(consumption, project_id, namespace_id)
        ::Ci::Minutes::UpdateProjectAndNamespaceUsageService.new(project_id, namespace_id).execute(consumption)
      end
    end
  end
end
