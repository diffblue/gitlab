# frozen_string_literal: true

module EE
  module Commits
    module CreateService
      extend ::Gitlab::Utils::Override

      private

      override :validate!
      def validate!
        super

        check_free_user_cap_over_limit! # order matters here, this needs to come before size check for storage limits
        validate_repository_size!
      end

      def check_free_user_cap_over_limit!
        ::Namespaces::FreeUserCap::Enforcement.new(project.root_ancestor)
                                              .git_check_over_limit!(::Commits::CreateService::ValidationError)
      end

      def validate_repository_size!
        if size_checker.above_size_limit?
          raise_error(size_checker.error_message.commit_error)
        end
      end

      def size_checker
        project.repository_size_checker
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
