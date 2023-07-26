# frozen_string_literal: true

module QA
  module EE
    module Resource
      # Common implementation for fetching group/project dora metrics
      #
      module DoraMetrics
        def api_dora_metrics_path
          "#{api_get_path}/dora/metrics"
        end

        # Fetch dora metrics, see: https://docs.gitlab.com/ee/api/dora/metrics.html
        #
        # @param [String] metric
        # @param [String] start_date
        # @param [String] end_date
        # @param [String] interval
        # @return [Array]
        def dora_metrics(metric:, start_date: nil, end_date: nil, interval: "all")
          response = get(
            request_url(
              api_dora_metrics_path,
              metric: metric,
              start_date: start_date,
              end_date: end_date,
              interval: interval
            )
          )

          parse_body(response).map { |entry| { date: entry[:date], value: entry[:value].round(2) } }
        end
      end
    end
  end
end
