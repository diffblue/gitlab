# frozen_string_literal: true

module Zoekt
  module SearchableRepository
    extend ActiveSupport::Concern

    INDEXING_TIMEOUT_S = 10.minutes.to_i

    class_methods do
      def truncate_zoekt_index!(shard)
        ::Gitlab::HTTP.post(
          URI.join(shard.index_base_url, zoekt_indexer_truncate_path),
          allow_local_requests: true
        )
      end

      def zoekt_indexer_truncate_path
        use_new_zoekt_indexer? ? '/indexer/truncate' : '/truncate'
      end

      def use_new_zoekt_indexer?
        ::Feature.enabled?(:use_new_zoekt_indexer)
      end
    end

    included do
      def use_zoekt?
        project&.use_zoekt?
      end

      def use_new_zoekt_indexer?
        self.class.use_new_zoekt_indexer?
      end

      def update_zoekt_index!
        use_new_zoekt_indexer? ? use_new_indexer! : use_legacy_indexer!
      end

      def async_update_zoekt_index
        ::Zoekt::IndexerWorker.perform_async(project.id)
      end

      private

      def zoekt_indexer_post(path, payload)
        ::Gitlab::HTTP.post(
          URI.join(zoekt_index_base_url, path),
          headers: { "Content-Type" => "application/json" },
          body: payload.to_json,
          allow_local_requests: true,
          timeout: INDEXING_TIMEOUT_S
        )
      end

      def use_legacy_indexer!
        payload = { CloneUrl: project.http_url_to_repo, RepoId: project.id }

        response = zoekt_indexer_post('/index', payload)

        raise response['Error'] if response['Error']

        response
      end

      def use_new_indexer!
        response = zoekt_indexer_post('/indexer/index', indexing_payload)

        raise response['Error'] if response['Error']
        raise "Request failed with: #{response.inspect}" unless response.success?

        response
      end

      def indexing_payload
        repository_storage = project.repository_storage
        connection_info = Gitlab::GitalyClient.connection_data(repository_storage)
        repository_path = "#{project.repository.disk_path}.git"
        address = connection_info['address']

        # This code is needed to support relative unix: connection strings. For example, specs
        if address.match?(%r{\Aunix:[^/.]})
          path = address.split('unix:').last
          address = "unix:#{Rails.root.join(path)}"
        end

        {
          GitalyConnectionInfo: {
            Address: address,
            Token: connection_info['token'],
            Storage: repository_storage,
            Path: repository_path
          },
          RepoId: project.id,
          FileSizeLimit: Gitlab::CurrentSettings.elasticsearch_indexed_file_size_limit_kb.kilobytes,
          Timeout: "#{INDEXING_TIMEOUT_S}s"
        }
      end

      def zoekt_index_base_url
        Zoekt::IndexedNamespace.where(namespace: project.root_namespace).first&.shard&.index_base_url
      end

      def zoekt_search_base_url
        Zoekt::IndexedNamespace.where(namespace: project.root_namespace).first&.shard&.search_base_url
      end
    end
  end
end
