# frozen_string_literal: true

module EE
  module Projects
    module TreeController
      extend ActiveSupport::Concern

      prepended do
        before_action do
          push_frontend_feature_flag(:remote_development_feature_flag)
          push_licensed_feature(:remote_development)
        end
      end
    end
  end
end
