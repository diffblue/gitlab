# frozen_string_literal: true

module Onboarding
  module Redirect
    extend ActiveSupport::Concern

    included do
      with_options if: :user_onboarding? do
        # We will handle the 2fa setup after onboarding if it is needed
        skip_before_action :check_two_factor_requirement
        before_action :onboarding_redirect
      end
    end

    private

    def onboarding_redirect
      return unless valid_for_onboarding_redirect?(current_user.user_detail.onboarding_step_url)

      redirect_to current_user.user_detail.onboarding_step_url
    end

    def user_onboarding?
      ::Onboarding.user_onboarding_in_progress?(current_user)
    end

    def valid_for_onboarding_redirect?(path)
      path.present? &&
        request.get? &&
        path != request.fullpath &&
        valid_referer?(path)
    end

    def valid_referer?(path)
      # do not redirect additional requests on the page
      # with current page as a referer
      request.referer.blank? || path.exclude?(URI(request.referer).path)
    end
  end
end
