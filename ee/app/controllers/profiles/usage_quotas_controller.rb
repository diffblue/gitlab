# frozen_string_literal: true

module Profiles
  class UsageQuotasController < Profiles::ApplicationController
    include OneTrustCSP
    include GoogleAnalyticsCSP

    feature_category :purchase
    urgency :low

    before_action :push_feature_flags, only: :index

    def index
      @hide_search_settings = true
      @namespace = current_user.namespace
    end

    private

    def push_feature_flags
      push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
    end
  end
end
