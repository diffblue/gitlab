# frozen_string_literal: true

module Admin
  module ApplicationSettings
    class ScimOauthController < Admin::ApplicationController
      feature_category :system_access
      before_action :check_feature_available

      # rubocop: disable CodeReuse/ActiveRecord
      def create
        scim_token = ScimOauthAccessToken.find_or_initialize_by(group: nil)

        if scim_token.new_record?
          scim_token.save
        else
          scim_token.reset_token!
        end

        respond_to do |format|
          format.json do
            if scim_token.errors.empty?
              render json: scim_token.as_entity_json
            else
              render json: { errors: scim_token.errors.full_messages }, status: :unprocessable_entity
            end
          end
        end
      end

      private

      def check_feature_available
        render_404 unless License.feature_available?(:instance_level_scim)
      end
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
