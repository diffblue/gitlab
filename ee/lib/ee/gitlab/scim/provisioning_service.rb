# frozen_string_literal: true
module EE
  module Gitlab
    module Scim
      class ProvisioningService < BaseProvisioningService
        def execute
          return error_response(errors: ["Missing params: #{missing_params}"]) unless missing_params.empty?
          return success_response if existing_identity?

          clear_memoization(:identity)

          return create_identity if existing_user?

          create_identity_and_user
        end

        private

        def create_identity
          return success_response if identity.save

          error_response(objects: [identity])
        end

        def identity
          ScimIdentity.with_extern_uid(@parsed_hash[:extern_uid]).first || build_scim_identity
        end
        strong_memoize_attr :identity

        def user
          ::User.find_by_any_email(@parsed_hash[:email]) || build_user
        end
        strong_memoize_attr :user

        def build_user
          ::Users::AuthorizedBuildService.new(nil, user_params.except(:extern_uid)).execute
        end

        def build_scim_identity
          ScimIdentity.new(
            user: user,
            extern_uid: @parsed_hash[:extern_uid],
            active: true
          )
        end

        def existing_identity?
          identity&.persisted?
        end

        def existing_user?
          user&.persisted?
        end

        def create_identity_and_user
          return success_response if user.save && identity.save

          error_response(objects: [identity, user])
        end

        def success_response
          ProvisioningResponse.new(status: :success, identity: identity)
        end
      end
    end
  end
end
