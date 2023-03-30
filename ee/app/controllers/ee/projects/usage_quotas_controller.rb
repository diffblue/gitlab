# frozen_string_literal: true

module EE
  module Projects
    module UsageQuotasController
      extend ActiveSupport::Concern

      prepended do
        before_action only: [:index] do
          push_frontend_feature_flag(:data_transfer_monitoring, project)
        end
      end
    end
  end
end
