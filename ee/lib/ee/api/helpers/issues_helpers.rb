# frozen_string_literal: true

module EE
  module API
    module Helpers
      module IssuesHelpers
        extend ActiveSupport::Concern

        prepended do
          params :optional_issue_params_ee do
            optional :weight, type: Integer, desc: 'The weight of the issue'
            optional :epic_id, type: Integer, desc: 'The ID of an epic to associate the issue with'
            optional :epic_iid, type: Integer, desc: 'The IID of an epic to associate the issue with (deprecated)'
            mutually_exclusive :epic_id, :epic_iid
          end

          params :negatable_issue_filter_params_ee do
            optional :weight, type: Integer, desc: 'Return issues without the specified weight'
            optional :iteration_id,
              types: [Integer, String],
              integer_or_custom_value: ::Iteration::Predefined::ALL.map { |iteration| iteration.name.downcase },
              desc: 'Return issues which are not assigned to the iteration with the given ID'
            optional :iteration_title,
              type: String,
              desc: 'Return issues which are not assigned to the iteration with the given title'
            mutually_exclusive :iteration_id, :iteration_title
          end

          params :issues_stats_params_ee do
            optional :weight, types: [Integer, String], integer_none_any: true, desc: 'The weight of the issue'
            optional :epic_id, types: [Integer, String], integer_none_any: true, desc: 'The ID of an epic associated with the issues'
            optional :health_status,
              type: String,
              values: ::IssuesFinder::Params::VALID_HEALTH_STATUS_PARAMS,
              desc: "The health status of the issue. Must be one of: #{::IssuesFinder::Params::VALID_HEALTH_STATUS_PARAMS.join(", ")}"
            optional :iteration_id,
              types: [Integer, String],
              integer_or_custom_value: ::Iteration::Predefined::ALL.map { |iteration| iteration.name.downcase },
              desc: 'Return issues which are assigned to the iteration with the given ID'
            optional :iteration_title,
              type: String,
              desc: 'Return issues which are assigned to the iteration with the given title'
            mutually_exclusive :iteration_id, :iteration_title
          end
        end

        class_methods do
          extend ::Gitlab::Utils::Override

          override :update_params_at_least_one_of
          def update_params_at_least_one_of
            [*super, :weight, :epic_id, :epic_iid]
          end

          override :sort_options
          def sort_options
            [*super, 'weight']
          end
        end
      end
    end
  end
end
