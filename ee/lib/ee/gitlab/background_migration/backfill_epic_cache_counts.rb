# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      module BackfillEpicCacheCounts
        extend ::Gitlab::Utils::Override
        extend ActiveSupport::Concern

        MAX_DEPTH = 7

        class Issue < ::ApplicationRecord # rubocop:disable Style/Documentation
        end

        class Epic < ::ApplicationRecord # rubocop:disable Style/Documentation
          ISSUE_STATES = {
            1 => 'opened',
            2 => 'closed'
          }.freeze

          def total_issue_weight_and_count
            subepic_sums = subepics_weight_and_count
            issue_sums = issues_weight_and_count

            {
              total_opened_issue_weight: subepic_sums[:opened_issue_weight] + issue_sums[:opened_issue_weight],
              total_closed_issue_weight: subepic_sums[:closed_issue_weight] + issue_sums[:closed_issue_weight],
              total_opened_issue_count: subepic_sums[:opened_issue_count] + issue_sums[:opened_issue_count],
              total_closed_issue_count: subepic_sums[:closed_issue_count] + issue_sums[:closed_issue_count]
            }
          end

          def subepics_weight_and_count
            sum = Epic.where(parent_id: id).select(
              'SUM(total_opened_issue_weight) AS opened_issue_weight',
              'SUM(total_closed_issue_weight) AS closed_issue_weight',
              'SUM(total_opened_issue_count) AS opened_issue_count',
              'SUM(total_closed_issue_count) AS closed_issue_count'
            )[0]

            {
              opened_issue_weight: sum.opened_issue_weight.to_i,
              closed_issue_weight: sum.closed_issue_weight.to_i,
              opened_issue_count: sum.opened_issue_count.to_i,
              closed_issue_count: sum.closed_issue_count.to_i
            }
          end

          def issues_weight_and_count
            state_sums = Issue
              .select('issues.state_id AS issues_state_id',
                      'SUM(COALESCE(issues.weight, 0)) AS issues_weight_sum',
                      'COUNT(issues.id) AS issues_count')
              .joins('INNER JOIN "epic_issues" ON "issues"."id" = "epic_issues"."issue_id"')
              .where('epic_issues.epic_id': id)
              .reorder(nil)
              .group("issues.state_id")

            by_state = state_sums.each_with_object({}) do |state_sum, result|
              key = ISSUE_STATES[state_sum.issues_state_id]
              result[key] = state_sum
            end

            {
              opened_issue_weight: by_state['opened']&.issues_weight_sum.to_i,
              closed_issue_weight: by_state['closed']&.issues_weight_sum.to_i,
              opened_issue_count: by_state['opened']&.issues_count.to_i,
              closed_issue_count: by_state['closed']&.issues_count.to_i
            }
          end
        end

        prepended do
          operation_name :update
        end

        override :perform
        def perform
          not_parent = 'NOT EXISTS (SELECT 1 FROM epics e WHERE e.parent_id = epics.id)'
          each_sub_batch(
            batching_scope: -> (relation) { relation.where(not_parent) }
          ) do |batch|
            update_epics(batch, level: 1)
          end
        end

        private

        def update_epics(batch, level:)
          if level > MAX_DEPTH
            logger.error(message: 'too deep epic hierarchy', ids: batch.pluck(:id))
            return
          end

          parent_ids = []

          batch.each do |epic|
            epic = epic.becomes(Epic) # rubocop:disable Cop/AvoidBecomes
            total_sums = epic.total_issue_weight_and_count
            epic.assign_attributes(total_sums)
            epic.save!(touch: false)
            parent_ids << epic.parent_id if epic.parent_id
          end

          return if parent_ids.empty?

          parents = Epic.where(id: parent_ids.uniq)
          update_epics(parents, level: level + 1)
        end

        def logger
          @logger ||= ::Gitlab::BackgroundMigration::Logger.build
        end
      end
    end
  end
end
