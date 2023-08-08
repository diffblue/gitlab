# frozen_string_literal: true

module Security
  class VulnerabilitiesController < ::Security::ApplicationController
    layout 'instance_security'

    before_action do
      push_frontend_feature_flag(:expose_dismissal_reason, @project)
    end
  end
end
