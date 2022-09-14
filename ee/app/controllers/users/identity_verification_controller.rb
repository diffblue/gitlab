# frozen_string_literal: true

module Users
  class IdentityVerificationController < ApplicationController
    include ZuoraCSP

    layout 'minimal'

    before_action :check_identity_verification_feature_flag

    feature_category :onboarding

    def show
    end

    protected

    def check_identity_verification_feature_flag
      access_denied! unless Feature.enabled?(:identity_verification, current_user)
    end
  end
end
