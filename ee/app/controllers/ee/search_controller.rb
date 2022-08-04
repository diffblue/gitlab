# frozen_string_literal: true

module EE
  module SearchController
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      # track unique users of advanced global search
      track_event :show, name: 'i_search_advanced',
        conditions: -> { track_search_advanced? },
        destinations: [:redis_hll, :snowplow]

      # track unique paid users (users who already use elasticsearch and users who could use it if they enable
      # elasticsearch integration)
      # for gitlab.com we check if the search uses elasticsearch
      # for self-managed we check if the licensed feature available
      track_event :show, name: 'i_search_paid',
        conditions: -> { track_search_paid? },
        destinations: [:redis_hll, :snowplow]

      rescue_from Elastic::TimeoutError, with: :render_timeout
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
