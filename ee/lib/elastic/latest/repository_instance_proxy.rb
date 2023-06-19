# frozen_string_literal: true

module Elastic
  module Latest
    class RepositoryInstanceProxy < ApplicationInstanceProxy
      include GitInstanceProxy

      delegate :project, to: :target
      delegate :group, to: :target
      delegate :id, to: :project, prefix: true, allow_nil: true
      delegate :id, to: :group, prefix: true, allow_nil: true

      def find_commits_by_message_with_elastic(query, page: 1, per_page: 20, options: {}, preload_method: nil)
        response = elastic_search(query, type: 'commit', options: options, page: page, per: per_page)[:commits][:results]

        commits = response.map do |result|
          commit result.dig('_source', 'sha')
        end.compact

        # Before "map" we had a paginated array so we need to recover it
        offset = per_page * ((page || 1) - 1)
        Kaminari.paginate_array(commits, total_count: response.total_count, limit: per_page, offset: offset)
      end

      private

      def repository_id
        project.id
      end
    end
  end
end
