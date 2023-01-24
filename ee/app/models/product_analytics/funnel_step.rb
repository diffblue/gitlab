# frozen_string_literal: true

module ProductAnalytics
  class FunnelStep
    include ActiveModel::Validations

    attr_reader :name, :target, :action

    validates! :action, inclusion: { in: %w[pageview] }

    def initialize(name:, target:, action:, funnel:)
      @name = name
      @target = target
      @action = action
      @funnel = funnel
    end

    def step_definition
      "doc_path = '#{target}'" if action == 'pageview'
    end
  end
end
