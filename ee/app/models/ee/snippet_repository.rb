# frozen_string_literal: true

module EE
  module SnippetRepository
    extend ActiveSupport::Concern

    EE_SEARCHABLE_ATTRIBUTES = %i[disk_path].freeze

    prepended do
      include ::Geo::ReplicableModel
      include ::Geo::VerifiableModel
      include ::Geo::VerificationStateDefinition
      include FromUnion
      include ::Gitlab::SQL::Pattern

      with_replicator ::Geo::SnippetRepositoryReplicator
    end

    class_methods do
      # Search for a list of snippet_repositories based on the query given in `query`.
      #
      # @param [String] query term that will search over snippet_repositories :disk_path attribute
      #
      # @return [ActiveRecord::Relation<SnippetRepository>] a collection of snippet repositories
      def search(query)
        return all if query.empty?

        fuzzy_search(query, EE_SEARCHABLE_ATTRIBUTES)
      end

      # @param primary_key_in [Range, SnippetRepository] arg to pass to primary_key_in scope
      # @return [ActiveRecord::Relation<SnippetRepository>] everything that should be synced to this node, restricted by primary key
      def replicables_for_current_secondary(primary_key_in)
        node = ::Gitlab::Geo.current_node

        replicables = if !node.selective_sync?
                        all
                      elsif node.selective_sync_by_namespaces?
                        snippet_repositories_for_selected_namespaces
                      elsif node.selective_sync_by_shards?
                        snippet_repositories_for_selected_shards
                      else
                        self.none
                      end

        replicables.primary_key_in(primary_key_in)
      end

      def snippet_repositories_for_selected_namespaces
        personal_snippets = self.joins(:snippet).where(snippet: ::Snippet.only_personal_snippets)

        project_snippets = self.joins(snippet: :project)
                               .merge(::Snippet.for_projects(::Gitlab::Geo.current_node.projects.select(:id)))

        self.from_union([project_snippets, personal_snippets])
      end

      def snippet_repositories_for_selected_shards
        self.for_repository_storage(::Gitlab::Geo.current_node.selective_sync_shards)
      end
    end
  end
end
