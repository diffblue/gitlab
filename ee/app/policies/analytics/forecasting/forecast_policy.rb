# frozen_string_literal: true

module Analytics
  module Forecasting
    class ForecastPolicy < ::BasePolicy
      condition(:deployment_frequency) do
        @subject.type == 'deployment_frequency'
      end

      condition(:can_read_dora4) do
        can?(:read_dora4_analytics, @subject.context)
      end

      rule { deployment_frequency & can_read_dora4 }.policy do
        enable :build_forecast
      end
    end
  end
end
