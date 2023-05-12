# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class RootSize < Namespaces::Storage::RootSize
      extend ::Gitlab::Utils::Override

      private

      override :valid_enforcement?
      def valid_enforcement?
        Feature.disabled?(:free_user_cap_without_storage_check)
      end
    end
  end
end
