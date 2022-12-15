# frozen_string_literal: true

module EE
  module Gitlab
    module Scim
      module Group
        class ProvisioningService < BaseProvisioningService
          def execute
            return error_response(errors: ["Missing params: #{missing_params}"]) unless missing_params.empty?
            return success_response if existing_identity_and_member?

            clear_memoization(:identity)

            return create_identity if create_identity_only?
            return create_identity_and_member if existing_user?

            create_user_and_member
          rescue StandardError => e
            logger.error(error: e.class.name, message: e.message, source: "#{__FILE__}:#{__LINE__}")

            error_response(errors: [e.message])
          end

          private

          def create_identity
            return success_response if identity.save

            error_response(objects: [identity])
          end

          def identity
            @group.scim_identities.with_extern_uid(@parsed_hash[:extern_uid]).first || build_scim_identity
          end
          strong_memoize_attr :identity

          def user
            ::User.find_by_any_email(@parsed_hash[:email]) || build_user
          end
          strong_memoize_attr :user

          def build_user
            ::Users::AuthorizedBuildService.new(nil, user_params).execute
          end

          def build_scim_identity
            @scim_identity ||=
              @group.scim_identities.new(
                user: user,
                extern_uid: @parsed_hash[:extern_uid],
                active: true
              )
          end

          def member
            return @group.member(user) if existing_member?(user)

            @group.add_member(user, default_membership_role) if user.valid?
          end
          strong_memoize_attr :member

          def default_membership_role
            @group.saml_provider.default_membership_role
          end

          def user_params
            @parsed_hash.tap do |hash|
              hash[:skip_confirmation] = SKIP_EMAIL_CONFIRMATION
              hash[:saml_provider_id] = @group.saml_provider.id
              hash[:group_id] = @group&.id
              hash[:provider] = ::Users::BuildService::GROUP_SCIM_PROVIDER
              hash[:username] = valid_username
              hash[:password] = hash[:password_confirmation] = random_password
              hash[:password_automatically_set] = PASSWORD_AUTOMATICALLY_SET
            end
          end

          def create_identity_and_member
            return success_response if member.valid? && identity.save

            error_response(objects: [identity, member])
          end

          def create_user_and_member
            return success_response if user.save && member.errors.empty?

            error_response(objects: [user, identity, member])
          end

          def create_identity_only?
            existing_user? && existing_member?(user)
          end

          def existing_identity_and_member?
            identity&.persisted? && existing_member?(identity.user)
          end

          def existing_member?(user)
            ::GroupMember.member_of_group?(@group, user)
          end

          def existing_user?
            user&.persisted?
          end

          def success_response
            ProvisioningResponse.new(status: :success, identity: identity)
          end
        end
      end
    end
  end
end
