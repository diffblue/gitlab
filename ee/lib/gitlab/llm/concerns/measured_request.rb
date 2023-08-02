# frozen_string_literal: true

module Gitlab
  module Llm
    module Concerns
      module MeasuredRequest
        extend ActiveSupport::Concern

        def increment_metric(client:, response: nil)
          success = (200...299).cover?(response&.code)

          Gitlab::Metrics::Sli::Apdex[:llm_client_request].increment(labels: { client: client }, success: success)
        end
      end
    end
  end
end
