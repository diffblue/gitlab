# frozen_string_literal: true

module Zoekt
  module SearchableRepository
    extend ActiveSupport::Concern

    READ_TIMEOUT_S = 10.minutes.to_i

    class_methods do
      def truncate_zoekt_index!(shard)
        ::Gitlab::HTTP.post(
          URI.join(shard.index_base_url, '/truncate'),
          allow_local_requests: true
        )
      end
    end

    included do
      def use_zoekt?
        project&.use_zoekt?
      end

      def update_zoekt_index!(use_local_disk_path: false)
        repository_url = if use_local_disk_path
                           path_to_repo
                         else
                           project.http_url_to_repo
                         end

        payload = { CloneUrl: repository_url, RepoId: project.id }

        response = ::Gitlab::HTTP.post(
          URI.join(zoekt_index_base_url, '/index'),
          headers: { "Content-Type" => "application/json" },
          body: payload.to_json,
          allow_local_requests: true,
          timeout: READ_TIMEOUT_S
        )

        raise response['Error'] if response['Error']

        response
      end

      def async_update_zoekt_index
        ::Zoekt::IndexerWorker.perform_async(project.id)
      end

      private

      def zoekt_index_base_url
        Zoekt::IndexedNamespace.where(namespace: project.root_namespace).first&.shard&.index_base_url
      end

      def zoekt_search_base_url
        Zoekt::IndexedNamespace.where(namespace: project.root_namespace).first&.shard&.search_base_url
      end
    end
  end
end
