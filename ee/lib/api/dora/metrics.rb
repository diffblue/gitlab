# frozen_string_literal: true

module API
  module Dora
    class Metrics < ::API::Base
      feature_category :continuous_delivery
      urgency :low

      dora_metrics_tags = %w[dora_metrics]

      helpers do
        params :dora_metrics_params do
          requires :metric,
            type: String,
            desc: 'One of `deployment_frequency`, `lead_time_for_changes`, `time_to_restore_service` or `change_failure_rate`' # rubocop:disable Layout/LineLength

          optional :start_date,
            type: Date,
            desc: 'Date range to start from. ISO 8601 Date format, for example `2021-03-01`. Default is 3 months ago'

          optional :end_date,
            type: Date,
            desc: 'Date range to end at. ISO 8601 Date format, for example `2021-03-01`. Default is the current date'

          optional :interval,
            type: String,
            desc: 'The bucketing interval. One of `all`, `monthly` or `daily`. Default is `daily`'

          optional :environment_tiers,
            type: Array[String],
            desc: 'The tiers of the environments. Default is `production`'
        end

        def fetch!(container)
          params = declared_params(include_missing: false)

          params[:metrics] = [params[:metric]] if params[:metric]

          result = ::Dora::AggregateMetricsService
            .new(container: container, current_user: current_user, params: params)
            .execute

          return render_api_error!(result[:message], result[:http_status]) unless result[:status] == :success

          present backwards_compatibility(result[:data])
        end

        def backwards_compatibility(data)
          params = declared_params(include_missing: false)
          metric = params[:metric]

          # @see https://gitlab.com/gitlab-org/gitlab/-/issues/334821
          return data.first[metric] if params[:interval] == :all

          data.map { |row| { 'date' => row['date'], 'value' => row[metric] } }
        end
      end

      params do
        requires :id,
          types: [String, Integer],
          desc: 'The ID or URL-encoded path of the project can be accessed by the authenticated user'
      end
      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        namespace ':id/dora/metrics' do
          desc 'Get project-level DORA metrics' do
            success [
              {
                code: 200,
                message: 'successful operation',
                examples: {
                  successfull_response: [
                    { "date" => "2021-03-01", "value" => 3 },
                    { "date" => "2021-03-02", "value" => 6 },
                    { "date" => "2021-03-03", "value" => 0 },
                    { "date" => "2021-03-04", "value" => 0 },
                    { "date" => "2021-03-05", "value" => 0 },
                    { "date" => "2021-03-06", "value" => 0 },
                    { "date" => "2021-03-07", "value" => 0 },
                    { "date" => "2021-03-08", "value" => 4 }
                  ]
                }
              }
            ]
            failure [
              { code: 400, message: 'Bad request' },
              { code: 401, message: 'Unauthorized' }
            ]
            is_array true
            tags dora_metrics_tags
          end
          params do
            use :dora_metrics_params
          end
          get do
            fetch!(user_project)
          end
        end
      end

      params do
        requires :id, type: String, desc: 'The ID of the group'
      end
      resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        namespace ':id/dora/metrics' do
          desc 'Get group-level DORA metrics' do
            success [
              {
                code: 200,
                message: 'successful operation',
                examples: {
                  successfull_response: [
                    { "date" => "2021-03-01", "value" => 3 },
                    { "date" => "2021-03-02", "value" => 6 },
                    { "date" => "2021-03-03", "value" => 0 },
                    { "date" => "2021-03-04", "value" => 0 },
                    { "date" => "2021-03-05", "value" => 0 },
                    { "date" => "2021-03-06", "value" => 0 },
                    { "date" => "2021-03-07", "value" => 0 },
                    { "date" => "2021-03-08", "value" => 4 }
                  ]
                }
              }
            ]
            failure [
              { code: 400, message: 'Bad request' },
              { code: 401, message: 'Unauthorized' }
            ]
            is_array true
            tags dora_metrics_tags
          end
          params do
            use :dora_metrics_params
          end
          get do
            fetch!(user_group)
          end
        end
      end
    end
  end
end
