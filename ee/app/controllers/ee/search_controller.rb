# frozen_string_literal: true

module EE
  module SearchController
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    class_methods do
      extend ::Gitlab::Utils::Override

      override :search_rate_limited_endpoints
      def search_rate_limited_endpoints
        super.push(:aggregations)
      end
    end

    prepended do
      # track unique users of advanced global search
      track_custom_event :show, name: 'i_search_advanced',
                                conditions: -> { track_search_advanced? },
                                label: 'redis_hll_counters.search.search_total_unique_counts_monthly',
                                action: 'executed',
                                destinations: [:redis_hll, :snowplow]

      # track unique paid users (users who already use elasticsearch and users who could use it if they enable
      # elasticsearch integration)
      # for gitlab.com we check if the search uses elasticsearch
      # for self-managed we check if the licensed feature available
      track_custom_event :show, name: 'i_search_paid',
                                conditions: -> { track_search_paid? },
                                label: 'redis_hll_counters.search.i_search_paid_monthly',
                                action: 'executed',
                                destinations: [:redis_hll, :snowplow]

      rescue_from Elastic::TimeoutError, with: :render_timeout

      before_action :check_search_rate_limit!, only: search_rate_limited_endpoints
    end

    def aggregations
      params.require([:search, :scope])

      if search_term_valid?
        render json: search_service.search_aggregations.to_json
      else
        render json: { error: flash[:alert] }, status: :bad_request
      end
    end

    private

    override :default_sort
    def default_sort
      if search_service.use_elasticsearch?
        'relevant'
      else
        super
      end
    end

    def track_search_advanced?
      search_service.use_elasticsearch?
    end

    def track_search_paid?
      if ::Gitlab.com?
        search_service.use_elasticsearch?
      else
        License.feature_available?(:elastic_search)
      end
    end

    def search_type
      track_search_advanced? ? 'advanced' : super
    end
  end
end
