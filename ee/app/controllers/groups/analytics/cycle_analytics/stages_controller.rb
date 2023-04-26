# frozen_string_literal: true

module Groups
  module Analytics
    module CycleAnalytics
      class StagesController < Groups::Analytics::ApplicationController
        include ::Analytics::CycleAnalytics::StageActions

        urgency :low

        private

        override :namespace
        def namespace
          @group
        end

        override :authorize_stage
        def authorize_stage
          return render_403 unless can?(current_user, :read_group_stage, @group)
        end
      end
    end
  end
end
