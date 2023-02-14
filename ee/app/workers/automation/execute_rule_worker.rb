# frozen_string_literal: true

module Automation
  class ExecuteRuleWorker
    include ApplicationWorker

    feature_category :no_code_automation
    data_consistency :always

    idempotent!

    def perform(rule_id)
      Gitlab::AppLogger.info 'Placeholder for performing automation rules'
    end
  end
end
