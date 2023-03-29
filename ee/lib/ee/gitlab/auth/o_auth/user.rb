# frozen_string_literal: true

module EE
  module Gitlab
    module Auth
      module OAuth
        module User
          extend ::Gitlab::Utils::Override

          def identity_verification_enabled?(user)
            user.identity_verification_enabled?
          end

          protected

          def activate_user_if_user_cap_not_reached
            if activate_user_based_on_user_cap?(gl_user)
              gl_user.activate
              log_user_changes(gl_user, protocol_name, "user cap not reached yet, unblocking")
            end
          end

          def find_ldap_person(auth_hash, adapter)
            if auth_hash.provider == 'kerberos'
              ::Gitlab::Auth::Ldap::Person.find_by_kerberos_principal(auth_hash.uid, adapter)
            else
              super
            end
          end

          def activate_user_based_on_user_cap?(user)
            return false unless user&.activate_based_on_user_cap?

            begin
              !::User.user_cap_reached?
            rescue ActiveRecord::QueryAborted => e
              ::Gitlab::ErrorTracking.track_exception(e, user_email: user.email)
              false
            end
          end

          def log_user_changes(user, protocol, message)
            ::Gitlab::AppLogger.info(
              "#{protocol}(#{auth_hash.provider}) account \"#{auth_hash.uid}\" #{message} " \
              "GitLab user \"#{user.name}\" (#{user.email})"
            )
          end

          override :build_new_user
          def build_new_user(skip_confirmation: true)
            super.tap do |user|
              next unless identity_verification_enabled?(user)

              user.confirmed_at = nil
              user.skip_confirmation_notification!
            end
          end
        end
      end
    end
  end
end
