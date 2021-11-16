# frozen_string_literal: true

require_dependency 'group_saml/saml_provider/base_service'

module GroupSaml
  module SamlProvider
    class CreateService < BaseService
      def initialize(current_user, group, params:)
        @group = group
        super(current_user, group.build_saml_provider, params: params)
      end

      def audit_name
        "#{super}_create"
      end
    end
  end
end
