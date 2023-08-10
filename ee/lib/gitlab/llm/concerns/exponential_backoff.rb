# frozen_string_literal: true

module Gitlab
  module Llm
    module Concerns
      module ExponentialBackoff
        extend ActiveSupport::Concern
        include ::Gitlab::Llm::Concerns::CircuitBreaker

        INITIAL_DELAY = 1.second
        EXPONENTIAL_BASE = 2
        MAX_RETRIES = 3

        RateLimitError = Class.new(StandardError)

        def self.included(base)
          base.extend(ExponentialBackoff)
        end

        def retry_methods_with_exponential_backoff(*method_names)
          method_names.each do |method_name|
            original_method = instance_method(method_name)

            define_method(method_name) do |*args, **kwargs|
              run_with_circuit do
                retry_with_exponential_backoff do
                  original_method.bind_call(self, *args, **kwargs)
                end
              end
            end
          end
        end

        private

        def retry_with_exponential_backoff
          retries = 0
          delay = INITIAL_DELAY

          loop do
            response = yield

            return unless response.present?

            http_response = response.response
            return if http_response.nil? || http_response.body.blank?

            raise Gitlab::Llm::Concerns::CircuitBreaker::InternalServerError if response.server_error?

            return response unless response.too_many_requests? || retry_immediately?(response)

            retries += 1
            raise RateLimitError, "Maximum number of retries (#{MAX_RETRIES}) exceeded." if retries >= MAX_RETRIES

            delay *= EXPONENTIAL_BASE * (1 + Random.rand)
            sleep delay
            next
          end
        end

        # Override in clients to create custom retry conditions, such as the content moderation retry
        # in the VertexAi::Client.
        def retry_immediately?(_response)
          false
        end
      end
    end
  end
end
