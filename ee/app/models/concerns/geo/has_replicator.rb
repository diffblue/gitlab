# frozen_string_literal: true

module Geo
  module HasReplicator
    extend ActiveSupport::Concern

    class_methods do
      # Associate current model with specified replicator
      #
      # @param [Gitlab::Geo::Replicator] klass
      def with_replicator(klass)
        raise ArgumentError, 'Must be a class inheriting from Gitlab::Geo::Replicator' unless
          klass < ::Gitlab::Geo::Replicator

        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          define_method :replicator do
            @_replicator ||= klass.new(model_record: self)
          end

          define_singleton_method :replicator_class do
            @_replicator_class ||= klass
          end
        RUBY
      end
    end

    # Geo Replicator
    #
    # @abstract
    # @return [Gitlab::Geo::Replicator]
    def replicator
      raise NotImplementedError, 'There is no Replicator defined for this model'
    end
  end
end
