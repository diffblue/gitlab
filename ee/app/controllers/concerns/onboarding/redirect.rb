# frozen_string_literal: true

module Onboarding
  module Redirect
    extend ActiveSupport::Concern

    included do
      before_action :onboarding_redirect
    end

    private

    def onboarding_redirect
      return unless Onboarding.user_onboarding_in_progress?(current_user)
      return unless valid_for_onboarding_redirect?(current_user.user_detail.onboarding_step_url)

      redirect_to current_user.user_detail.onboarding_step_url
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
