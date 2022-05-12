# frozen_string_literal: true

module PushRules
  class CreateOrUpdateService < BaseContainerService
    def execute
      push_rule = container.push_rule || container.build_push_rule

      if push_rule.update(params)
        ::Audit::GroupPushRulesChangesAuditor.new(current_user, push_rule).execute
        ServiceResponse.success(payload: { push_rule: push_rule })
      else
        error_message = push_rule.errors.full_messages.to_sentence
        ServiceResponse.error(message: error_message, payload: { push_rule: push_rule })
      end
    end
  end
end
