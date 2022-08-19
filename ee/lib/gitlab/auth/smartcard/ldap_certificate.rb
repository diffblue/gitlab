# frozen_string_literal: true

module Gitlab
  module Auth
    module Smartcard
      class LdapCertificate < Gitlab::Auth::Smartcard::Base
        def initialize(provider, certificate)
          super(certificate)

          @provider = provider
        end

        def auth_method
          'smartcard_ldap'
        end

        private

        def find_user
          identity = Identity.find_by_extern_uid(@provider, ldap_user.dn)
          identity&.user
        end

        def create_identity_for_existing_user
          user = User.find_by_email(ldap_user.email.first)

          return if user.nil? || user.ldap_user?

          create_ldap_certificate_identity_for(user)
          user
        end

        def create_user
          user_params = {
            name: ldap_user.name,
            username: username,
            email: ldap_user.email.first,
            extern_uid: ldap_user.dn,
            provider: @provider,
            password: password,
            password_confirmation: password,
            password_automatically_set: true,
            skip_confirmation: true
          }

          Users::AuthorizedCreateService.new(nil, user_params).execute
        end

        def create_ldap_certificate_identity_for(user)
          user.identities.create(provider: @provider, extern_uid: ldap_user.dn)
        end

        def adapter
          @adapter ||= Gitlab::Auth::Ldap::Adapter.new(@provider)
        end

        def ldap_user
          @ldap_user ||= ::Gitlab::Auth::Ldap::Person.find_by_certificate_issuer_and_serial(
            @certificate.issuer.to_s(OpenSSL::X509::Name::RFC2253),
            @certificate.serial.to_s,
            adapter)
        end

        def username
          ::Namespace.clean_path(ldap_user.username)
        end
      end
    end
  end
end
