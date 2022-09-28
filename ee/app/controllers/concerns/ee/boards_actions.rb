# frozen_string_literal: true

module EE
  module BoardsActions
    extend ActiveSupport::Concern

    private

    def push_licensed_features
      # This is pushing a licensed Feature to the frontend.
      push_licensed_feature(:wip_limits) if parent.feature_available?(:wip_limits)
      push_licensed_feature(:swimlanes) if parent.feature_available?(:swimlanes)
      push_licensed_feature(:issue_weights) if parent.feature_available?(:issue_weights)
    end
  end
end
