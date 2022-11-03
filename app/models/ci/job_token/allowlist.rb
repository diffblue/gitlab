# frozen_string_literal: true
module Ci
  module JobToken
    class Allowlist
      def initialize(source_project, direction:)
        @source_project = source_project
        @direction = direction
      end

      def includes?(target_project)
        self_referential?(target_project) || added?(target_project)
      end

      def all_projects
        Project.from_union(target_projects, remove_duplicates: false)
      end

      private

      def self_referential?(target_project)
        target_project.id == @source_project.id
      end

      def added?(target_project)
        source_links
          .with_target(target_project)
          .where(direction: @direction)
          .exists?
      end

      def target_project_ids
        source_links
          .where(direction: @direction)
          # pluck needed to avoid ci and main db join
          .pluck(:target_project_id)
      end

      def source_links
        Ci::JobToken::ProjectScopeLink
          .with_source(@source_project)
      end

      def target_projects
        [
          Project.id_in(@source_project),
          Project.id_in(target_project_ids)
        ]
      end
    end
  end
end
