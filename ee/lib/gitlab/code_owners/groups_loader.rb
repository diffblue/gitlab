# frozen_string_literal: true

module Gitlab
  module CodeOwners
    class GroupsLoader
      def initialize(project, extractor)
        @project = project
        @extractor = extractor
      end

      def load_to(entries)
        groups = load_groups
        entries.each do |entry|
          entry.add_matching_groups_from(groups)
        end
      end

      private

      attr_reader :extractor, :project

      def load_groups
        return Group.none if extractor.names.empty?

        relations = [
          project.invited_groups.where_full_path_in(extractor.names, use_includes: false)
        ]
        # Include the projects ancestor group(s) if they are listed as owners
        if project.group
          relations << project.group.self_and_ancestors.where_full_path_in(extractor.names, use_includes: false)
        end

        Group.from_union(relations).with_route.with_users
      end
    end
  end
end
