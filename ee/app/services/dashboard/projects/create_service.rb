# frozen_string_literal: true

module Dashboard
  module Projects
    class CreateService
      Result = Struct.new(:added_project_ids, :not_found_project_ids, :not_licensed_project_ids, :duplicate_project_ids) do
        def invalid_project_ids
          not_found_project_ids + not_licensed_project_ids
        end
      end

      def initialize(user, projects_relation, feature: nil, ability: nil)
        @user = user
        @projects_relation = projects_relation
        @feature = feature
        @ability = ability
      end

      def execute(project_ids)
        found_projects = find_projects(project_ids)
        licensed_projects = select_available_projects(found_projects)

        not_found = find_invalid_ids(found_projects, project_ids)
        not_licensed = find_invalid_ids(licensed_projects, project_ids) - not_found

        added, duplicate = add_projects(licensed_projects)

        Result.new(added.map(&:id), not_found, not_licensed, duplicate.map(&:id))
      end

      private

      attr_reader :feature,
                  :ability,
                  :projects_relation,
                  :user

      def find_projects(project_ids)
        ProjectsFinder.new(
          current_user: user,
          project_ids_relation: project_ids,
          params: projects_finder_params
        ).execute
      end

      def projects_finder_params
        return {} if user.can?(:read_all_resources)

        {
          min_access_level: ProjectMember::DEVELOPER
        }
      end

      def select_available_projects(projects)
        projects
          .select { |project| feature.blank? || project.feature_available?(feature) }
          .select { |project| ability.blank? || user.can?(ability, project) }
      end

      def find_invalid_ids(projects_to_add, project_ids)
        found_ids = projects_to_add.map(&:id)

        project_ids.map(&:to_i) - found_ids
      end

      def add_projects(projects)
        projects.partition { |project| add_project(project) }
      end

      def add_project(project)
        projects_relation << project
        true
      rescue ActiveRecord::RecordInvalid
        false
      end
    end
  end
end
