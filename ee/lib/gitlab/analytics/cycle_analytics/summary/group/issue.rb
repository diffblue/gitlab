# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module Summary
        module Group
          class Issue < Group::Base
            attr_reader :group, :current_user, :options

            def initialize(group:, current_user:, options:)
              @group = group
              @current_user = current_user
              @options = options
            end

            def identifier
              :issues
            end

            def title
              n_('New Issue', 'New Issues', value.to_i)
            end

            def value
              @value ||= ::Gitlab::CycleAnalytics::Summary::Value::PrettyNumeric.new(issues_count)
            end

            private

            def issues_count
              issues = IssuesFinder.new(current_user, finder_params).execute
              issues = issues.of_projects(options[:projects]) if options[:projects].present?
              issues.count
            end

            def finder_params
              options.dup.tap do |hash|
                hash.delete(:projects)
                hash[:created_after] = hash.delete(:from)
                hash[:created_before] = hash.delete(:to)
                hash[:group_id] = group.id
                hash[:include_subgroups] = true
              end
            end
          end
        end
      end
    end
  end
end
