# frozen_string_literal: true

module Elastic
  module MigrationOptions
    extend ActiveSupport::Concern
    include Gitlab::ClassAttributes

    DEFAULT_THROTTLE_DELAY = 3.minutes
    DEFAULT_BATCH_SIZE = 1000
    DEFAULT_MAX_ATTEMPTS = 30

    def batched?
      self.class.get_batched
    end

    def batch_size
      self.class.get_batch_size
    end

    def throttle_delay
      self.class.get_throttle_delay
    end

    def pause_indexing?
      self.class.get_pause_indexing
    end

    def space_requirements?
      self.class.get_space_requirements
    end

    def retry_on_failure?
      max_attempts.present?
    end

    def max_attempts
      self.class.get_max_attempts
    end

    class_methods do
      def space_requirements!
        class_attributes[:space_requirements] = true
      end

      def get_space_requirements
        class_attributes[:space_requirements]
      end

      def batched!
        class_attributes[:batched] = true
      end

      def get_batched
        class_attributes[:batched]
      end

      def pause_indexing!
        class_attributes[:pause_indexing] = true
      end

      def get_pause_indexing
        class_attributes[:pause_indexing]
      end

      def throttle_delay(value)
        class_attributes[:throttle_delay] = value
      end

      def get_throttle_delay
        class_attributes[:throttle_delay] || DEFAULT_THROTTLE_DELAY
      end

      def batch_size(value)
        class_attributes[:batch_size] = value
      end

      def get_batch_size
        class_attributes[:batch_size] || DEFAULT_BATCH_SIZE
      end

      def retry_on_failure(max_attempts: DEFAULT_MAX_ATTEMPTS)
        class_attributes[:max_attempts] = max_attempts
      end

      def get_max_attempts
        class_attributes[:max_attempts]
      end
    end
  end
end
