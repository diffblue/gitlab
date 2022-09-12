# frozen_string_literal: true

module API
  module Helpers
    module PersonalAccessTokensHelpers
      InvalidParamsError = Class.new(StandardError)

      def finder_params(current_user)
        user_param =
          if current_user.can_admin_all_resources?
            { user: user(params[:user_id]) }
          else
            { user: current_user, impersonation: false }
          end

        declared(params, include_missing: false).merge(user_param)
      end

      def params_validator!
        # rubocop:disable Style/GuardClause
        unless filter_by_created_at_valid?
          raise InvalidParamsError, 'The filter which searches for token created after a specific date cannot be larger
           than creation date'
        end

        unless filter_by_last_used_at_valid?
          raise InvalidParamsError, 'When using last used date filter, last_used_before date should be greater than or
           equal to last_used_after date.'
        end
        # rubocop:enable Style/GuardClause
      end

      def filter_by_created_at_valid?
        return true unless params[:created_before] && params[:created_after]

        params[:created_after] <= params[:created_before]
      end

      def filter_by_last_used_at_valid?
        return true unless params[:last_used_before] && params[:last_used_after]

        params[:last_used_after] <= params[:last_used_before]
      end

      def user(user_id)
        UserFinder.new(user_id).find_by_id
      end

      def restrict_non_admins!
        return if params[:user_id].blank?

        unauthorized! unless Ability.allowed?(current_user, :read_user_personal_access_tokens, user(params[:user_id]))
      end

      def find_token(id)
        PersonalAccessToken.find(id) || not_found!
      end

      def revoke_token(token)
        service = ::PersonalAccessTokens::RevokeService.new(current_user, token: token).execute

        service.success? ? no_content! : bad_request!(nil)
      end
    end
  end
end
