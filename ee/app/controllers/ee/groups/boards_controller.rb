# frozen_string_literal: true

module EE
  module Groups
    module BoardsController
      extend ActiveSupport::Concern

      prepended do
        before_action do
          push_force_frontend_feature_flag(:iteration_cadences, group&.iteration_cadences_feature_flag_enabled?)
        end
      end
    end
  end
end
