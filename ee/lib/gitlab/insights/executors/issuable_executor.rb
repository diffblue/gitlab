# frozen_string_literal: true

module Gitlab
  module Insights
    module Executors
      class IssuableExecutor
        def initialize(query_params:, current_user:, insights_entity:, projects: [], chart_type:)
          @query_params = query_params
          @current_user = current_user
          @insights_entity = insights_entity
          @projects = projects
          @chart_type = chart_type
        end

        def execute
          issuables = finder.find
          insights = reduce(
            issuables: issuables,
            period_limit: finder.period_limit,
            period_field: period_field_param || finder.period_field
          )
          serializer.present(insights)
        end

        private

        attr_reader :query_params, :current_user, :insights_entity, :projects, :chart_type

        def serializer
          case chart_type
          when 'stacked-bar'
            Gitlab::Insights::Serializers::Chartjs::MultiSeriesSerializer
          when 'bar', 'pie'
            if group_by_param
              Gitlab::Insights::Serializers::Chartjs::BarTimeSeriesSerializer
            else
              Gitlab::Insights::Serializers::Chartjs::BarSerializer
            end
          when 'line'
            Gitlab::Insights::Serializers::Chartjs::LineSerializer
          end
        end

        def reduce(issuables:, period_limit:, period_field:)
          case chart_type
          when 'stacked-bar', 'line'
            Gitlab::Insights::Reducers::LabelCountPerPeriodReducer.reduce(
              issuables,
              period: group_by_param,
              period_limit: period_limit,
              period_field: period_field,
              labels: collection_labels_param
            )
          when 'bar', 'pie'
            if group_by_param
              Gitlab::Insights::Reducers::CountPerPeriodReducer.reduce(
                issuables,
                period: group_by_param,
                period_limit: period_limit,
                period_field: period_field
              )
            else
              # Performance optimization to use Index Only Scan
              issuables = issuables.select(:id).reorder(id: :desc) # rubocop:disable CodeReuse/ActiveRecord

              Gitlab::Insights::Reducers::CountPerLabelReducer.reduce(
                issuables,
                labels: collection_labels_param
              )
            end
          end
        end

        def finder
          @finder ||=
            Gitlab::Insights::Finders::IssuableFinder
            .new(insights_entity, current_user,
                 query: query_params, projects: projects)
        end

        def period_field_param
          @period_field_param ||= query_params[:period_field]
        end

        def group_by_param
          @group_by_param ||= query_params[:group_by]
        end

        def collection_labels_param
          @collection_labels_param ||= query_params[:collection_labels]
        end
      end
    end
  end
end
