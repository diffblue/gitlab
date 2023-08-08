# frozen_string_literal: true

module Namespaces
  module CombinedStorageUsers
    module PreEnforcement
      def over_both_limits?(root_namespace)
        over_storage_limit?(root_namespace) && over_user_limit?(root_namespace)
      end

      def over_storage_limit?(root_namespace)
        ::Namespaces::Storage::Enforcement.show_pre_enforcement_alert?(root_namespace)
      end

      def over_user_limit?(root_namespace)
        # We use `EnforcementWithoutStorage` so we don't check `above_size_limit?`
        # and only check for number of users
        ::Namespaces::FreeUserCap::EnforcementWithoutStorage.new(root_namespace).over_limit?
      end
    end
  end
end
