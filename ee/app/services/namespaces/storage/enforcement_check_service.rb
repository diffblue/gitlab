# frozen_string_literal: true

module Namespaces
  module Storage
    class EnforcementCheckService
      def self.enforce_limit?(namespace)
        ::Gitlab::CurrentSettings.enforce_namespace_storage_limit? &&
          ::Feature.enabled?(:namespace_storage_limit, namespace)
      end
    end
  end
end
