# frozen_string_literal: true

module EE
  module WebHooks
    module AutoDisabling
      extend ActiveSupport::Concern

      EE_ENABLED_HOOK_TYPES = %w[GroupHook].freeze

      class_methods do
        extend ::Gitlab::Utils::Override

        private

        override :enabled_hook_types
        def enabled_hook_types
          super + EE_ENABLED_HOOK_TYPES
        end
      end
    end
  end
end
