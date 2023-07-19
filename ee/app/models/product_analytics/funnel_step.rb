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
      path_name = 'page_urlpath'
      "#{path_name} = '#{target}'" if action == 'pageview'
    end
  end
end
