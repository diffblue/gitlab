# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module Summary
        module Group
          class DeploymentFrequency < Group::Base
            include Gitlab::CycleAnalytics::GroupProjectsProvider
            include Gitlab::CycleAnalytics::SummaryHelper

            def initialize(deployments:, group:, options:)
              @deployments = deployments

              super(group: group, options: options)
            end

            def title
              _('Deployment Frequency')
            end

            def value
              @value ||= frequency(@deployments, options[:from], options[:to] || Time.current)
            end

            def unit
              _('/day')
            end

            def links
              [
                { "name" => _('Deployment frequency'), "url" => Gitlab::Routing.url_helpers.group_analytics_ci_cd_analytics_path(group, tab: 'deployment-frequency'), "label" => s_('ValueStreamAnalytics|Dashboard') },
                { "name" => _('Deployment frequency'), "url" => Gitlab::Routing.url_helpers.help_page_path('user/analytics/index', anchor: 'definitions'), "docs_link" => true, "label" => s_('ValueStreamAnalytics|Go to docs') }
              ]
            end
          end
        end
      end
    end
  end
end
