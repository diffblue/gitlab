# frozen_string_literal: true

module Security
  class VulnerabilitiesController < ::Security::ApplicationController
    layout 'instance_security'

    before_action do
      push_frontend_feature_flag(:refactor_vulnerability_tool_filter, @project)
      push_frontend_feature_flag(:refactor_vulnerability_filters, current_user)
    end
  end
end
