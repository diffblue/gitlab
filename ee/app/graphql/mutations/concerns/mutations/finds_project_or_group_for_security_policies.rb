# frozen_string_literal: true

module Mutations
  module FindsProjectOrGroupForSecurityPolicies
    private

    def find_object(**args)
      full_path = args[:project_path].presence || args[:full_path]

      if full_path.blank?
        raise Gitlab::Graphql::Errors::ArgumentError,
              'At least one of the arguments fullPath or projectPath is required'
      end

      project = find_project(full_path)
      group = find_group(full_path) if project.nil?

      raise_resource_not_available_error! if group.nil? && project.nil?

      project || group
    end

    def find_project(full_path)
      Project.find_by_full_path(full_path)
    end

    def find_group(full_path)
      Group.find_by_full_path(full_path)
    end
  end
end
