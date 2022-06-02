# frozen_string_literal: true

module EE
  module Gitlab
    module Auth
      module OAuth
        module AuthHash
          include ::Gitlab::Utils::StrongMemoize

          def kerberos_default_realm
            ::Gitlab::Kerberos::Authentication.kerberos_default_realm
          end

          def uid
            strong_memoize(:ee_uid) do
              ee_uid = super

              # For Kerberos, usernames `principal` and `principal@DEFAULT.REALM`
              # are equivalent and may be used indifferently.
              # Normalize here the uid to always have the canonical Kerberos
              # principal name with realm.
              # See https://gitlab.com/gitlab-org/gitlab/-/issues/41
              if provider == 'kerberos' && ee_uid.present?
                ee_uid = "#{ee_uid}@#{kerberos_default_realm}" unless ee_uid.include?('@')
              end

              ee_uid
            end
          end
        end
      end
    end
  end
end
