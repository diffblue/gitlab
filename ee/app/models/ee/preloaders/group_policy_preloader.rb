# frozen_string_literal: true

module EE
  module Preloaders
    module GroupPolicyPreloader
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        super

        ::Preloaders::GroupRootAncestorPreloader.new(groups, root_ancestor_preloads).execute
        ::Gitlab::GroupPlansPreloader.new.preload(groups) if ::Gitlab::CurrentSettings.should_check_namespace_plan?
      end

      private

      def root_ancestor_preloads
        [:ip_restrictions, :saml_provider]
      end
    end
  end
end
