# frozen_string_literal: true

module Projects
  class AutomationsController < Projects::ApplicationController
    feature_category :no_code_automation

    before_action :feature_enabled!
    before_action do
      push_frontend_feature_flag(:no_code_automation_mvc, project)
    end

    def index; end

    private

    def feature_enabled!
      if ::Feature.disabled?(:no_code_automation_mvc, project) ||
          !project.licensed_feature_available?(:no_code_automation)
        render_404
      end
    end
  end
end
