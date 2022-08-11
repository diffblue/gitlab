# frozen_string_literal: true

module EE
  module API
    module Helpers
      module UsersHelpers
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          params :optional_params_ee do
            optional :shared_runners_minutes_limit, type: Integer, desc: 'Pipeline minutes quota for this user'
            optional :extra_shared_runners_minutes_limit, type: Integer, desc: '(admin-only) Extra pipeline minutes quota for this user'
            optional :group_id_for_saml, type: Integer, desc: 'ID for group where SAML has been configured'
            optional :auditor, type: Grape::API::Boolean, desc: 'Flag indicating auditor status of the user'
          end

          params :optional_index_params_ee do
            optional :skip_ldap, type: Grape::API::Boolean, default: false, desc: 'Skip LDAP users'
            optional :saml_provider_id, type: Integer, desc: 'Return only users from the specified SAML provider Id'
          end
        end
      end
    end
  end
end
