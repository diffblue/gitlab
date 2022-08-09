# frozen_string_literal: true

module Gitlab
  module Insights
    module Finders
      class ProjectsFinder
        include Gitlab::Utils::StrongMemoize

        def initialize(projects_param)
          @projects_param = projects_param
        end

        def execute
          finder_projects
        end

        private

        attr_reader :projects_param

        def finder_projects
          strong_memoize(:finder_projects) do
            if projects_param.empty?
              nil
            elsif finder_projects_options[:ids] && finder_projects_options[:paths]
              Project.from_union([finder_projects_ids, finder_projects_paths])
            elsif finder_projects_options[:ids]
              finder_projects_ids
            elsif finder_projects_options[:paths]
              finder_projects_paths
            end
          end
        end

        def finder_projects_ids
          Project.id_in(finder_projects_options[:ids]).select(:id)
        end

        def finder_projects_paths
          Project.where_full_path_in(
            finder_projects_options[:paths], use_includes: false
          ).select(:id)
        end

        def finder_projects_options
          @finder_projects_options ||= projects_param[:only]&.group_by do |item|
            case item
            when Integer
              :ids
            when String
              :paths
            else
              :unknown
            end
          end || {}
        end
      end
    end
  end
end
