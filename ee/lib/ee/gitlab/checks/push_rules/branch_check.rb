# frozen_string_literal: true

module EE
  module Gitlab
    module Checks
      module PushRules
        class BranchCheck < ::Gitlab::Checks::BaseSingleChecker
          ERROR_MESSAGE = "Branch name '%{branch_name}' does not follow the pattern '%{branch_name_regex}'"
          LOG_MESSAGE = "Checking if branch follows the naming patterns defined by the project..."

          def validate!
            return unless push_rule

            logger.log_timed(LOG_MESSAGE) do
              unless branch_name_allowed_by_push_rule?
                message = ERROR_MESSAGE % { branch_name: branch_name, branch_name_regex: push_rule.branch_name_regex }
                raise ::Gitlab::GitAccess::ForbiddenError, message
              end
            end

            PushRules::CommitCheck.new(change_access).validate!
          rescue ::PushRule::MatchError => e
            raise ::Gitlab::GitAccess::ForbiddenError, e.message
          end

          private

          def branch_name_allowed_by_push_rule?
            return true if skip_branch_name_push_rule?

            push_rule.branch_name_allowed?(branch_name)
          end

          def skip_branch_name_push_rule?
            deletion? ||
              branch_name.blank? ||
              branch_name == project.default_branch
          end
        end
      end
    end
  end
end
