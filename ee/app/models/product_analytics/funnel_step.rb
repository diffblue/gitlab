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
      path_name = Feature.enabled?(:product_analytics_snowplow_support) ? 'page_urlpath' : 'doc_path'
      "#{path_name} = '#{target}'" if action == 'pageview'
    end
  end
end
