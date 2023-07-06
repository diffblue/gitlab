# frozen_string_literal: true

module EE
  module Gitlab
    module ApplicationContext
      extend ::Gitlab::Utils::Override
      extend ActiveSupport::Concern

      Attribute = Struct.new(:name, :type)

      EE_KNOWN_KEYS = [
        :subscription_plan,
        :ai_resource
      ].freeze

      EE_APPLICATION_ATTRIBUTES = [
        Attribute.new(:ai_resource, ::GlobalID)
      ].freeze

      class_methods do
        extend ::Gitlab::Utils::Override

        override :known_keys
        def known_keys
          super + EE_KNOWN_KEYS
        end

        override :application_attributes
        def application_attributes
          super + EE_APPLICATION_ATTRIBUTES
        end
      end

      override :to_lazy_hash
      def to_lazy_hash
        super.tap do |hash|
          assign_hash_if_value(hash, :ai_resource)

          hash[:subscription_plan] = -> { subcription_plan_name } if include_namespace?
        end
      end

      def subcription_plan_name
        object = namespace
        # Avoid loading the project's namespace if it wasn't loaded
        object ||= project.namespace if project&.association(:namespace)&.loaded?
        # Avoid loading or creating a plan if it wasn't already.
        return unless object&.strong_memoized?(:actual_plan)

        object&.actual_plan_name
      end
    end
  end
end
