# frozen_string_literal: true

module Gitlab
  module CodeOwners
    FILE_NAME = 'CODEOWNERS'
    FILE_PATHS = [FILE_NAME, "docs/#{FILE_NAME}", ".gitlab/#{FILE_NAME}"].freeze

    def self.for_blob(project, blob)
      if project.feature_available?(:code_owners)
        Loader.new(project, blob.commit_id, blob.path).members
      else
        []
      end
    end

    # @param project [Project]
    # @param ref [String]
    # Fetch sections from CODEOWNERS file
    def self.sections(project, ref)
      return [] unless project.feature_available?(:code_owners)

      Loader.new(project, ref, []).code_owners_sections
    end

    # @param project [Project]
    # @param ref [String]
    # @param section [String]
    # Checks whether all entries are optional
    def self.optional_section?(project, ref, section)
      return false unless project.feature_available?(:code_owners)

      Loader.new(project, ref, []).optional_section?(section)
    end

    # @param merge_request [MergeRequest]
    # @param merge_request_diff [MergeRequestDiff]
    #   Find code owners entries at a particular MergeRequestDiff.
    #   Assumed to be the most recent one if not provided.
    def self.entries_for_merge_request(merge_request, merge_request_diff: nil)
      return [] unless merge_request.project.feature_available?(:code_owners)

      loader_for_merge_request(merge_request, merge_request_diff)&.entries || []
    end

    # @param merge_request [MergeRequest]
    # @param sha [String]
    #   Find code owners entries since the specified commit.
    #   Assumed to be the most recent one if not provided.
    def self.entries_since_merge_request_commit(merge_request, sha: nil)
      return [] unless merge_request.project.feature_available?(:code_owners)

      sha ||= merge_request.commit_shas(limit: 2).last
      paths = merge_request.merge_request_diff.compare_with(sha).modified_paths
      Loader.new(
        merge_request.target_project,
        merge_request.target_branch,
        paths)&.entries || []
    end

    def self.loader_for_merge_request(merge_request, merge_request_diff)
      return if merge_request.source_project.nil? || merge_request.source_branch.nil?
      return unless merge_request.target_project.feature_available?(:code_owners)

      Loader.new(
        merge_request.target_project,
        merge_request.target_branch,
        paths_for_merge_request(merge_request, merge_request_diff)
      )
    end
    private_class_method :loader_for_merge_request

    def self.paths_for_merge_request(merge_request, merge_request_diff)
      # NOTE: merge_head_diff is preferred as we want to include latest changes from the target branch
      merge_request_diff ||= merge_request.merge_head_diff || merge_request.merge_request_diff

      merge_request_diff.modified_paths(fallback_on_overflow: true)
    end
    private_class_method :paths_for_merge_request
  end
end
