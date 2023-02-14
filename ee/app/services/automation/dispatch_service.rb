# frozen_string_literal: true

module Automation
  class DispatchService < ::BaseContainerService
    def execute(data, hook)
      container.automation_rules.hooks_for(hook).each do |rule|
        Automation::ExecuteRuleWorker.perform_async(rule.id)
      end
    end
  end
end
