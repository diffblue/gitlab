# frozen_string_literal: true

module Gitlab
  module Geo
    class RegistryBatcher < BaseBatcher
      def initialize(registry_class, key:, batch_size: 1000)
        super(registry_class::MODEL_CLASS, registry_class, registry_class::MODEL_FOREIGN_KEY, key: key, batch_size: batch_size)
      end
    end
  end
end
