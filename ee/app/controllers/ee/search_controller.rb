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
      track_event :show,
        name: 'i_search_advanced',
        conditions: -> { track_search_advanced? },
        label: 'redis_hll_counters.search.search_total_unique_counts_monthly',
        action: 'executed',
        destinations: [:redis_hll, :snowplow]

      # track unique paid users (users who already use elasticsearch and users who could use it if they enable
      # elasticsearch integration)
      # for gitlab.com we check if the search uses elasticsearch
      # for self-managed we check if the licensed feature available
      track_event :show,
        name: 'i_search_paid',
        conditions: -> { track_search_paid? },
        label: 'redis_hll_counters.search.i_search_paid_monthly',
        action: 'executed',
        destinations: [:redis_hll, :snowplow]

      rescue_from Elastic::TimeoutError, with: :render_timeout

      before_action :check_search_rate_limit!, only: search_rate_limited_endpoints

      after_action :run_index_integrity_worker, only: :show, if: :no_results_for_group_or_project_blobs_advanced_search?
    end

    def aggregations
      params.require(:search)

      # Cache the response on the frontend
      cache_for = ::Gitlab.com? ? 5.minutes : 1.minute
      expires_in cache_for

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

    # rubocop:disable Gitlab/ModuleWithInstanceVariables
    def no_results_for_group_or_project_blobs_advanced_search?
      return false unless ::Feature.enabled?(:search_index_integrity)
      return false unless @scope == 'blobs'
      return false unless @project || @group
      return false unless search_service.use_elasticsearch?

      @search_objects.blank?
    end

    def run_index_integrity_worker
      if @project.present?
        ::Search::ProjectIndexIntegrityWorker.perform_async(@project.id)
      else
        ::Search::NamespaceIndexIntegrityWorker.perform_async(@group.id)
      end
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables
  end
end
