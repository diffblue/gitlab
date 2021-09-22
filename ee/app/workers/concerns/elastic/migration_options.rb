# frozen_string_literal: true

module Elastic
  module MigrationOptions
    extend ActiveSupport::Concern
    include Gitlab::ClassAttributes

    DEFAULT_THROTTLE_DELAY = 5.minutes

    def batched?
      self.class.get_batched
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
    end
  end
end
