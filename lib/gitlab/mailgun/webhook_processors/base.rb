# frozen_string_literal: true

module Gitlab
  module Mailgun
    module WebhookProcessors
      class Base
        def initialize(payload)
          @payload = payload
        end

        def execute
          raise NotImplementedError
        end

        def should_process?
          raise NotImplementedError
        end

        private

        attr_reader :payload
      end
    end
  end
end
