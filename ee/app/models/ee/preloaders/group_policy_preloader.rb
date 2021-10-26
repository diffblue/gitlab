# frozen_string_literal: true

module EE
  module Preloaders
    module GroupPolicyPreloader
      extend ::Gitlab::Utils::Override

      private

      override :root_ancestor_preloads
      def root_ancestor_preloads
        [*super, :ip_restrictions, :saml_provider]
      end
    end
  end
end
