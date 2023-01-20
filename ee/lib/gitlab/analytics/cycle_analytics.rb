# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      def self.licensed?(subject)
        case subject
        when Namespaces::ProjectNamespace
          subject.licensed_feature_available?(:cycle_analytics_for_projects)
        when Group
          subject.licensed_feature_available?(:cycle_analytics_for_groups)
        else
          false
        end
      end
    end
  end
end
