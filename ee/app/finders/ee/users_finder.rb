# frozen_string_literal: true

module EE
  module UsersFinder
    extend ::Gitlab::Utils::Override

    override :execute
    def execute
      users = by_non_ldap(super)
      by_saml_provider_id(users)
    end

    def by_non_ldap(users)
      return users unless params[:skip_ldap]

      users.non_ldap
    end

    def by_saml_provider_id(users)
      saml_provider_id = params[:by_saml_provider_id]
      return users unless saml_provider_id

      users.limit_to_saml_provider(saml_provider_id)
    end
  end
end
