# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class ApprovalProjectRulesWithUserMetric < DatabaseMetric
          operation :count

          metric_options do
            {
              batch_size: 10_000
            }
          end

          start { ApprovalProjectRule.regular.minimum(:id) }
          finish { ApprovalProjectRule.regular.maximum(:id) }

          def to_sql
            ApplicationRecord.select(Arel.star.count).from("(#{super}) subquery").to_sql
          end

          def value
            super.size
          end

          private

          def relation
            ApprovalProjectRule
              .regular
              .joins('INNER JOIN approval_project_rules_users ON approval_project_rules_users.approval_project_rule_id = approval_project_rules.id')
              .group(:id)
              .having(having_clause)
          end

          def having_clause
            case options[:count_type]
            when 'more_approvers_than_required'
              'COUNT(approval_project_rules_users) > approvals_required'
            when 'less_approvers_than_required'
              'COUNT(approval_project_rules_users) < approvals_required'
            when 'exact_required_approvers'
              'COUNT(approval_project_rules_users) = approvals_required'
            end
          end
        end
      end
    end
  end
end
