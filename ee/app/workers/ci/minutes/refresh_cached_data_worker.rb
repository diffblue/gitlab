# frozen_string_literal: true

module Ci
  module Minutes
    class RefreshCachedDataWorker
      include ApplicationWorker
      include PipelineBackgroundQueue

      data_consistency :always
      idempotent!

      def perform(root_namespace_id)
        ::Namespace.find_by_id(root_namespace_id).try do |root_namespace|
          ::Ci::Minutes::RefreshCachedDataService.new(root_namespace).execute
        end
      end
    end
  end
end
