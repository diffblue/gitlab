# frozen_string_literal: true

module Security
  class VulnerabilitiesController < ::Security::ApplicationController
    layout 'instance_security'

    before_action do
      push_frontend_feature_flag(:vulnerability_management_survey, type: :ops, default_enabled: :yaml)
    end
  end
end
