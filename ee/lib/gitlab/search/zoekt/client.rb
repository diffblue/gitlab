# frozen_string_literal: true

module Gitlab
  module Search
    module Zoekt
      class Client # rubocop:disable Search/NamespacedClass
        INDEXING_TIMEOUT_S = 30.minutes.to_i

        class << self
          def instance
            @instance ||= new
          end

          delegate :search, :index, :truncate, to: :instance
        end

        def search(query, num:, project_ids:)
          start = Time.current

          body = {
            Q: query,
            Opts: {
              TotalMaxMatchCount: num,
              NumContextLines: 1
            }
          }

          # Safety net because Zoekt will match all projects if you provide
          # an empty array.
          raise "Not possible to search without at least one project specified" if project_ids == []

          body[:RepoIDs] = project_ids unless project_ids == :any

          path = '/api/search'
          request_body = body.to_json
          response = ::Gitlab::HTTP.post(
            URI.join(search_base_url, path),
            headers: { "Content-Type" => "application/json" },
            body: request_body,
            allow_local_requests: true
          )

          unless response.success?
            logger.error(message: "Zoekt search failed", status: response.code, response: response.body)
          end

          ::Gitlab::Json.parse(response.body, symbolize_names: true)
        ensure
          add_request_details(start_time: start, path: path, body: request_body)
        end

        def index(project)
          use_new_zoekt_indexer? ? index_with_new_indexer(project) : index_with_legacy_indexer(project)
        end

        def truncate
          ::Gitlab::HTTP.post(
            URI.join(index_base_url, zoekt_indexer_truncate_path),
            allow_local_requests: true
          )
        end

        private

        def zoekt_indexer_post(path, payload)
          ::Gitlab::HTTP.post(
            URI.join(index_base_url, path),
            headers: { "Content-Type" => "application/json" },
            body: payload.to_json,
            allow_local_requests: true,
            timeout: INDEXING_TIMEOUT_S
          )
        end

        def index_with_legacy_indexer(project)
          payload = { CloneUrl: project.http_url_to_repo, RepoId: project.id }

          response = zoekt_indexer_post('/index', payload)

          raise response['Error'] if response['Error']

          response
        end

        def index_with_new_indexer(project)
          response = zoekt_indexer_post('/indexer/index', indexing_payload(project))

          raise response['Error'] if response['Error']
          raise "Request failed with: #{response.inspect}" unless response.success?

          response
        end

        def indexing_payload(project)
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

        def shard
          # TODO: https://gitlab.com/gitlab-org/gitlab-build-images/-/issues/118
          # Today we only support a single shard so just choose first
          ::Zoekt::Shard.first
        end

        def index_base_url
          shard.index_base_url
        end

        def search_base_url
          shard.search_base_url
        end

        def add_request_details(start_time:, path:, body:)
          return unless ::Gitlab::SafeRequestStore.active?

          duration = (Time.current - start_time)

          ::Gitlab::Instrumentation::Zoekt.increment_request_count
          ::Gitlab::Instrumentation::Zoekt.add_duration(duration)

          ::Gitlab::Instrumentation::Zoekt.add_call_details(
            duration: duration,
            method: 'POST',
            path: path,
            body: body
          )
        end

        def zoekt_indexer_truncate_path
          use_new_zoekt_indexer? ? '/indexer/truncate' : '/truncate'
        end

        def use_new_zoekt_indexer?
          ::Feature.enabled?(:use_new_zoekt_indexer)
        end

        def logger
          @logger ||= ::Zoekt::Logger.build
        end
      end
    end
  end
end
