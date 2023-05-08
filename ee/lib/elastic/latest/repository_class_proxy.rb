# frozen_string_literal: true

module Elastic
  module Latest
    class RepositoryClassProxy < ApplicationClassProxy
      include GitClassProxy

      def es_type
        'blob'
      end

      # @return [Kaminari::PaginatableArray]
      def find_commits_by_message_with_elastic(query, page: 1, per_page: 20, options: {}, preload_method: nil)
        elastic_search_and_wrap(query, type: 'commit', page: page, per: per_page, options: options, preload_method: preload_method) do |result, project|
          raw_commit = Gitlab::Git::Commit.new(
            project.repository.raw,
            prepare_commit(result),
            lazy_load_parents: true
          )

          Commit.new(raw_commit, project)
        end
      end

      private

      def prepare_commit(raw_result)
        source = raw_result['_source']

        {
          id: source['sha'],
          message: source['message'],
          parent_ids: nil,
          author_name: source['author']['name'],
          author_email: source['author']['email'],
          authored_date: Time.parse(source['author']['time']).utc,
          committer_name: source['committer']['name'],
          committer_email: source['committer']['email'],
          committed_date: Time.parse(source['committer']['time']).utc
        }
      end
    end
  end
end
