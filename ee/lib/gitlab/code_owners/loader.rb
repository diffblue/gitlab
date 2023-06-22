# frozen_string_literal: true

module Gitlab
  module CodeOwners
    class Loader
      include ::Gitlab::Utils::StrongMemoize

      def initialize(project, ref, paths = [])
        @project = project
        @ref = ref
        @paths = Array(paths)
      end

      def entries
        return [] if empty_code_owners?

        strong_memoize(:entries) do
          entries = load_bare_entries_for_paths

          # a single extractor is used here, since usernames and groupnames
          # share the same pattern. This way we don't need to match it twice.
          owner_lines = entries.map(&:owner_line)
          extractor = Gitlab::CodeOwners::ReferenceExtractor.new(owner_lines)

          UsersLoader.new(@project, extractor).load_to(entries)
          GroupsLoader.new(@project, extractor).load_to(entries)

          entries
        end
      end

      def members
        strong_memoize(:members) do
          entries.flat_map(&:all_users).uniq
        end
      end

      def empty_code_owners?
        code_owners_file.empty?
      end

      def code_owners_path
        code_owners_file&.path
      end

      def code_owners_sections
        code_owners_file&.sections
      end

      def optional_section?(section)
        code_owners_file&.optional_section?(section)
      end

      def file_valid?
        code_owners_file.valid?
      end
      strong_memoize_attr :file_valid?

      def file_errors
        file_valid?
        code_owners_file.errors
      end
      strong_memoize_attr :file_errors

      def track_file_validation
        return if file_valid?

        file_errors.each do |error|
          Gitlab::Tracking.event(
            self.class.name,
            'file_validation',
            label: error.message.to_s,
            project: @project,
            extra: {
              file_path: error.path,
              line_number: error.line_number
            }
          )
        end
      end

      private

      def load_bare_entries_for_paths
        entries = @paths.map do |path|
          code_owners_file.entries_for_path(path)
        end

        entries.flatten.compact.uniq
      end

      def code_owners_file
        @code_owners_file ||= Gitlab::SafeRequestStore.fetch("project-#{@project.id}:code-owners:#{@ref}") do
          load_code_owners_file
        end
      end

      def load_code_owners_file
        code_owners_blob = @project.repository.code_owners_blob(ref: @ref)
        Gitlab::CodeOwners::File.new(code_owners_blob)
      end
    end
  end
end
