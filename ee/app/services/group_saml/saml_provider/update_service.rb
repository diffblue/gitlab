# frozen_string_literal: true

require_dependency 'group_saml/saml_provider/base_service'

module GroupSaml
  module SamlProvider
    class UpdateService < BaseService
      def audit_name
        "#{super}_update"
      end
    end
  end
end
