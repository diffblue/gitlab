# frozen_string_literal: true

module Gitlab
  module Auth
    module Smartcard
      class Certificate < Gitlab::Auth::Smartcard::Base
        include Gitlab::Utils::StrongMemoize

        def auth_method
          'smartcard'
        end

        private

        def find_user
          User.find_by_smartcard_identity(subject, issuer)
        end

        def create_identity_for_existing_user
          User.find_by_email(email).tap do |user|
            create_smartcard_identity_for(user) if user
          end
        end

        def create_user
          user_params = {
            name: common_name,
            username: username,
            email: email,
            password: password,
            password_confirmation: password,
            password_automatically_set: true,
            certificate_subject: subject,
            certificate_issuer: issuer,
            skip_confirmation: true
          }

          Users::AuthorizedCreateService.new(nil, user_params).execute
        end

        def create_smartcard_identity_for(user)
          SmartcardIdentity.create(user: user, subject: subject, issuer: issuer)
        end

        def issuer
          @certificate.issuer.to_s
        end

        def subject
          @certificate.subject.to_s
        end

        def common_name
          subject.split('/').find { |part| part.include?('CN=') }&.remove('CN=')&.strip
        end

        def email
          strong_memoize(:email) do
            if san_enabled?
              san_extension.email_identity
            else
              subject.split('/').find { |part| part.include?('emailAddress=') }&.remove('emailAddress=')&.strip
            end
          end
        end

        def san_enabled?
          Gitlab.config.smartcard.san_extensions
        end

        def san_extension
          @san_extension ||= SANExtension.new(@certificate, Gitlab.config.gitlab.host)
        end

        def username
          ::Namespace.clean_path(common_name)
        end
      end
    end
  end
end
