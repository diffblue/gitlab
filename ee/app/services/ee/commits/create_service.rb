# frozen_string_literal: true

module EE
  module Commits
    module CreateService
      extend ::Gitlab::Utils::Override

      private

      override :validate!
      def validate!
        super

        validate_repository_size!
      end

      def validate_repository_size!
        if size_checker.above_size_limit?
          raise_error(size_checker.error_message.commit_error)
        end
      end

      def size_checker
        root_namespace = project.namespace.root_ancestor

        if ::EE::Gitlab::Namespaces::Storage::Enforcement.enforce_limit?(root_namespace)
          ::EE::Namespace::RootStorageSize.new(root_namespace)
        else
          project.repository_size_checker
        end
      end

      def extracted_paths
        paths = []

        paths << params[:file_path].presence
        paths << paths_from_actions
        paths << paths_from_start_sha
        paths << paths_from_commit(params[:commit])

        paths.flatten.compact.uniq
      end

      def paths_from_actions
        return unless params[:actions].present?

        params[:actions].flat_map do |entry|
          [entry[:file_path], entry[:previous_path]]
        end
      end

      def paths_from_start_sha
        return unless params[:start_sha].present?

        commit = project.commit(params[:start_sha])
        return unless commit

        paths_from_commit(commit)
      end

      def paths_from_commit(commit)
        return unless commit.present?

        commit.raw_deltas.flat_map { |diff| [diff.new_path, diff.old_path] }
      end
    end
  end
end
