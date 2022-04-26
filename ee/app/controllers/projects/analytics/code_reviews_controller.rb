# frozen_string_literal: true

module Projects
  module Analytics
    class CodeReviewsController < Projects::ApplicationController
      include RedisTracking

      before_action :authorize_read_code_review_analytics!

      track_redis_hll_event :index, name: 'p_analytics_code_reviews'

      feature_category :value_stream_management
      urgency :low

      def index
      end
    end
  end
end
