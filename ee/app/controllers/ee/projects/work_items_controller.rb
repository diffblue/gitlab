# frozen_string_literal: true

module EE
  module Projects
    module WorkItemsController
      extend ActiveSupport::Concern

      prepended do
        before_action do
          push_force_frontend_feature_flag(:okrs_mvc, project&.okrs_mvc_feature_flag_enabled?)
        end
      end
    end
  end
end
