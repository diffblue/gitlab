# frozen_string_literal: true

module API
  module Analytics
    class ProjectDeploymentFrequency < ::API::Base
      include Gitlab::Utils::StrongMemoize

      QUARTER_DAYS = 3.months / 1.day
      DEPLOYMENT_FREQUENCY_INTERVAL_ALL = 'all'
      DEPLOYMENT_FREQUENCY_INTERVAL_MONTHLY = 'monthly'
      DEPLOYMENT_FREQUENCY_INTERVAL_DAILY = 'daily'
      DEPLOYMENT_FREQUENCY_DEFAULT_INTERVAL = DEPLOYMENT_FREQUENCY_INTERVAL_ALL
      VALID_INTERVALS = [
        DEPLOYMENT_FREQUENCY_INTERVAL_ALL,
        DEPLOYMENT_FREQUENCY_INTERVAL_MONTHLY,
        DEPLOYMENT_FREQUENCY_INTERVAL_DAILY
      ].freeze

      feature_category :value_stream_management
      urgency :low

      before do
        authenticate!
      end

      helpers do
        def environment_name
          params[:environment]
        end

        def start_date
          params[:from]
        end

        def end_date
          params[:to] || DateTime.current
        end

        def days_between
          (end_date - start_date).to_i
        end

        def interval
          params[:interval] || DEPLOYMENT_FREQUENCY_DEFAULT_INTERVAL
        end

        def deployments
          strong_memoize(:deployments) do
            ::DeploymentsFinder.new(
              project: user_project,
              environment: environment_name,
              finished_after: start_date,
              finished_before: end_date,
              status: :success,
              order_by: :finished_at
            ).execute
          end
        end

        def deployments_grouped
          strong_memoize(:deployments_grouped) do
            case interval
            when DEPLOYMENT_FREQUENCY_INTERVAL_ALL
              { start_date => deployments }
            when DEPLOYMENT_FREQUENCY_INTERVAL_MONTHLY
              deployments.group_by { |d| d.finished_at.beginning_of_month }
            when DEPLOYMENT_FREQUENCY_INTERVAL_DAILY
              deployments.group_by { |d| d.finished_at.to_date }
            end
          end
        end

        def deployments_grouped_end_date(deployments_grouped_start_date)
          case interval
          when DEPLOYMENT_FREQUENCY_INTERVAL_ALL
            end_date
          when DEPLOYMENT_FREQUENCY_INTERVAL_MONTHLY
            deployments_grouped_start_date + 1.month
          when DEPLOYMENT_FREQUENCY_INTERVAL_DAILY
            deployments_grouped_start_date + 1.day
          end
        end

        def deployment_frequencies
          strong_memoize(:deployment_frequencies) do
            deployments_grouped.map do |grouped_start_date, grouped_deploys|
              {
                value: grouped_deploys.count,
                from: grouped_start_date,
                to: deployments_grouped_end_date(grouped_start_date)
              }
            end
          end
        end
      end

      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
      end

      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        namespace ':id/analytics' do
          desc 'List deployment frequencies for the project' do
            is_array true
            success EE::API::Entities::Analytics::DeploymentFrequency
          end
          params do
            requires :environment, type: String, desc: 'Name of the environment to filter by'
            requires :from, type: DateTime, desc: 'Datetime to start from, inclusive'
            optional :to, type: DateTime, desc: 'Datetime to end at, exclusive'
            optional :interval, type: String, desc: 'Interval to roll-up data by', values: VALID_INTERVALS
          end
          get 'deployment_frequency' do
            bad_request!("Parameter `to` is before the `from` date") if start_date > end_date
            bad_request!("Date range is greater than #{QUARTER_DAYS} days") if days_between > QUARTER_DAYS
            authorize! :read_dora4_analytics, user_project
            present deployment_frequencies, with: EE::API::Entities::Analytics::DeploymentFrequency
          end
        end
      end
    end
  end
end
