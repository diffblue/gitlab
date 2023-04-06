# frozen_string_literal: true

module Geo
  class RepositoryVerificationFinder
    def initialize(shard_name: nil)
      @shard_name = shard_name
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def find_failed_repositories(batch_size:)
      query = build_query_to_find_failed_projects(type: :repository, batch_size: batch_size)
      cte   = Gitlab::SQL::CTE.new(:failed_repositories, query)

      project_with_select_all.with(cte.to_arel)
             .from(cte.alias_to(projects_table))
             .order("projects.repository_retry_at ASC")
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_failed_wikis(batch_size:)
      query = build_query_to_find_failed_projects(type: :wiki, batch_size: batch_size)
      cte   = Gitlab::SQL::CTE.new(:failed_wikis, query)

      project_with_select_all.with(cte.to_arel)
             .from(cte.alias_to(projects_table))
             .order("projects.wiki_retry_at ASC")
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_recently_updated_projects(batch_size:)
      query = build_query_to_find_recently_updated_projects(batch_size: batch_size)
      cte   = Gitlab::SQL::CTE.new(:recently_updated_projects, query)

      project_with_select_all.with(cte.to_arel)
             .from(cte.alias_to(projects_table))
             .order(last_repository_updated_at_asc)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_never_verified_projects(batch_size:)
      relation =
        Project.select(:id)
         .with_route
         .joins(left_join_repository_state)
         .where(repository_state_table[:project_id].eq(nil))
         .limit(batch_size)

      apply_shard_restriction(relation)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def find_reverifiable_repositories(interval:, batch_size:)
      build_query_to_find_reverifiable_projects(type: :repository, interval: interval, batch_size: batch_size)
    end

    def find_reverifiable_wikis(interval:, batch_size:)
      build_query_to_find_reverifiable_projects(type: :wiki, interval: interval, batch_size: batch_size)
    end

    def count_verified_repositories
      ProjectRepositoryState.verified_repos.count
    end

    def count_verified_wikis
      ProjectRepositoryState.verified_wikis.count
    end

    def count_verification_failed_repositories
      ProjectRepositoryState.verification_failed_repos.count
    end

    def count_verification_failed_wikis
      ProjectRepositoryState.verification_failed_wikis.count
    end

    private

    attr_reader :shard_name

    # rubocop: disable CodeReuse/ActiveRecord
    def build_query_to_find_failed_projects(type:, batch_size:)
      query =
        projects_table
          .join(repository_state_table).on(project_id_matcher)
          .project(projects_table[:id], repository_state_table["#{type}_retry_at"])
          .where(
            repository_state_table["#{type}_retry_at"].lt(Time.now)
              .and(repository_state_table["last_#{type}_verification_failure"].not_eq(nil))
          ).take(batch_size)

      apply_shard_restriction(query)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def build_query_to_find_recently_updated_projects(batch_size:)
      repository_recently_updated =
        repository_state_table[:repository_verification_checksum].eq(nil)
          .and(repository_state_table[:last_repository_verification_failure].eq(nil))

      where_clause =
        if ::Geo::ProjectWikiRepositoryReplicator.enabled?
          repository_recently_updated
        else
          wiki_recently_updated =
            repository_state_table[:wiki_verification_checksum].eq(nil)
              .and(repository_state_table[:last_wiki_verification_failure].eq(nil))

          repository_recently_updated.or(wiki_recently_updated)
        end

      query =
        projects_table
          .join(repository_state_table).on(project_id_matcher)
          .project(projects_table[:id], projects_table[:last_repository_updated_at])
          .where(where_clause)
          .take(batch_size)

      apply_shard_restriction(query)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def build_query_to_find_reverifiable_projects(type:, interval:, batch_size:)
      verification_succeded =
        repository_state_table["#{type}_verification_checksum"].not_eq(nil)
          .and(repository_state_table["last_#{type}_verification_failure"].eq(nil))

      verified_before_interval =
        repository_state_table["last_#{type}_verification_ran_at"].eq(nil).or(
          repository_state_table["last_#{type}_verification_ran_at"].lteq(interval))

      query =
        projects_table
          .join(repository_state_table).on(project_id_matcher)
          .project(projects_table[:id], projects_table[:last_repository_updated_at])
          .where(verification_succeded.and(verified_before_interval))
          .take(batch_size)

      query = apply_shard_restriction(query)
      cte = Gitlab::SQL::CTE.new(:reverifiable_projects, query)

      # We should prioritize less active projects first because high active
      # projects have their repositories verified more frequently.
      project_with_select_all.with(cte.to_arel)
             .from(cte.alias_to(projects_table))
             .order(last_repository_updated_at_asc)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def project_with_select_all
      Project.select(projects_table[Arel.star])
    end

    def projects_table
      Project.arel_table
    end

    def repository_state_table
      ProjectRepositoryState.arel_table
    end

    def project_id_matcher
      projects_table[:id].eq(repository_state_table[:project_id])
    end

    def left_join_repository_state
      projects_table
        .join(repository_state_table, Arel::Nodes::OuterJoin)
        .on(project_id_matcher)
        .join_sources
    end

    def last_repository_updated_at_asc
      Project.arel_table[:last_repository_updated_at].asc.nulls_last
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def apply_shard_restriction(query)
      return query unless shard_name.present?

      query.where(projects_table[:repository_storage].eq(shard_name))
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
