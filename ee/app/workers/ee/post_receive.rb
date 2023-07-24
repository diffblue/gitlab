# frozen_string_literal: true

module EE
  # PostReceive EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `PostReceive` worker
  module PostReceive
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    private

    # rubocop:disable Gitlab/NoCodeCoverageComment
    # :nocov: undercoverage spec keeps failing here, it's tested in ee/spec/workers/post_receive_spec.rb
    def after_project_changes_hooks(project, user, refs, changes)
      super

      return unless ::Gitlab::Geo.primary?

      if ::Geo::ProjectRepositoryReplicator.enabled?
        project.geo_handle_after_update
      else
        ::Geo::RepositoryUpdatedService.new(project.repository, refs: refs, changes: changes).execute
      end
    end
    # :nocov:
    # rubocop:enable Gitlab/NoCodeCoverageComment

    def process_wiki_changes(post_received, wiki)
      super

      if wiki.is_a?(ProjectWiki)
        process_project_wiki_changes(wiki)
      else
        process_group_wiki_changes(wiki)
      end
    end

    def process_project_wiki_changes(wiki)
      project_wiki_repository = wiki.project.wiki_repository
      project_wiki_repository.geo_handle_after_update if project_wiki_repository
    end

    def process_group_wiki_changes(wiki)
      return unless wiki.group.group_wiki_repository

      wiki.group.group_wiki_repository.geo_handle_after_update
    end

    override :replicate_snippet_changes
    def replicate_snippet_changes(snippet)
      if ::Gitlab::Geo.primary?
        # We don't use Geo::RepositoryUpdatedService anymore as
        # it's already deprecated. See https://gitlab.com/groups/gitlab-org/-/epics/2809
        snippet.snippet_repository.geo_handle_after_update if snippet.snippet_repository
      end
    end

    override :replicate_design_management_repository_changes
    def replicate_design_management_repository_changes(design_management_repository)
      return unless ::Gitlab::Geo.primary?
      return unless ::Geo::DesignManagementRepositoryReplicator.enabled?

      design_management_repository.geo_handle_after_update if design_management_repository
    end
  end
end
