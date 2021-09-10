# frozen_string_literal: true

module EE
  module ServicePing
    module BuildPayloadService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        return super unless ::License.current.present?

        filtered_usage_data(super)
      end

      private

      override :product_intelligence_enabled?
      def product_intelligence_enabled?
        ::License.current&.customer_service_enabled? || super
      end

      def filtered_usage_data(payload = raw_payload, parents = [])
        return unless payload.is_a?(Hash)

        payload.keep_if do |label, node|
          if has_metric_definition?(label, parents)
            permitted_metric?(label, parents)
          else
            filtered_usage_data(node, parents.dup << label) if node.is_a?(Hash)
          end
        end
      end

      def permitted_categories
        @permitted_categories ||= ::ServicePing::PermitDataCategoriesService.new.execute
      end

      def permitted_metric?(key, parent_keys)
        permitted_categories.include?(metric_category(key, parent_keys))
      end

      def has_metric_definition?(key, parent_keys)
        key_path = parent_keys.dup.append(key).join('.')
        metric_definitions[key_path].present?
      end

      def metric_category(key, parent_keys)
        key_path = parent_keys.dup.append(key).join('.')
        metric_definitions[key_path]
          &.attributes
          &.fetch(:data_category, ::ServicePing::PermitDataCategoriesService::OPTIONAL_CATEGORY)
      end

      def metric_definitions
        @metric_definitions ||= ::Gitlab::Usage::MetricDefinition.definitions
      end
    end
  end
end
