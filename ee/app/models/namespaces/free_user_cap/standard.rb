# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class Standard < Base
      def reached_limit?
        return false unless enforce_cap?

        users_count >= limit
      end

      private

      def limit
        if new_namespace_enforcement?
          Namespaces::FreeUserCap.dashboard_limit
        else
          ::Gitlab::CurrentSettings.dashboard_enforcement_limit
        end
      end

      def new_namespace_enforcement?
        return false unless ::Feature.enabled?(:free_user_cap_new_namespaces, root_namespace)
        return false unless ::Gitlab::CurrentSettings.dashboard_limit_new_namespace_creation_enforcement_date.present?

        root_namespace.created_at >= ::Gitlab::CurrentSettings.dashboard_limit_new_namespace_creation_enforcement_date
      end

      def feature_enabled?
        ::Feature.enabled?(:free_user_cap, root_namespace) || new_namespace_enforcement?
      end
    end
  end
end

Namespaces::FreeUserCap::Standard.prepend_mod
