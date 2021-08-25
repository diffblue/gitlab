# frozen_string_literal: true

require 'tempfile'

module Geo
  class ContainerRepositorySync
    include Gitlab::Utils::StrongMemoize

    FOREIGN_MEDIA_TYPE = 'application/vnd.docker.image.rootfs.foreign.diff.tar.gzip'

    attr_reader :repository_path, :container_repository

    def initialize(container_repository)
      @container_repository = container_repository
      @repository_path = container_repository.path
    end

    def execute
      tags_to_sync.each { |tag| sync_tag(tag) }
      tags_to_remove.each { |tag| remove_tag(tag) }

      true
    end

    private

    def sync_tag(tag)
      manifest = client.repository_raw_manifest(repository_path, tag[:name])
      manifest_parsed = Gitlab::Json.parse(manifest)

      case manifest_parsed['mediaType']
      when ContainerRegistry::Client::DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE
        push_manifest_blobs(manifest_parsed)
      when ContainerRegistry::Client::DOCKER_DISTRIBUTION_MANIFEST_LIST_V2_TYPE
        manifest_parsed['manifests'].each do |submanifest|
          image_info_raw = client.repository_raw_manifest(repository_path, submanifest['digest'])
          image_info = Gitlab::Json.parse(image_info_raw)
          push_manifest_blobs(image_info)
          container_repository.push_manifest(submanifest['digest'], image_info_raw, image_info['mediaType'])
        end
      else
        raise "Unexpected mediaType: #{manifest_parsed['mediaType']}"
      end
      container_repository.push_manifest(tag[:name], manifest, manifest_parsed['mediaType'])
    end

    def push_manifest_blobs(manifest)
      list_blobs(manifest).each do |digest|
        next if container_repository.blob_exists?(digest)

        file = client.pull_blob(repository_path, digest)
        begin
          container_repository.push_blob(digest, file.path)
        ensure
          file.unlink
        end
      end
    end

    def remove_tag(tag)
      container_repository.delete_tag_by_digest(tag[:digest])
    end

    def list_blobs(manifest)
      layers = manifest['layers'].filter_map do |layer|
        layer['digest'] unless foreign_layer?(layer)
      end

      layers.push(manifest.dig('config', 'digest')).compact
    end

    def foreign_layer?(layer)
      layer['mediaType'] == FOREIGN_MEDIA_TYPE
    end

    def primary_tags
      strong_memoize(:primary_tags) do
        manifest = client.repository_tags(repository_path)
        next [] unless manifest && manifest['tags']

        manifest['tags'].map do |tag|
          { name: tag, digest: client.repository_tag_digest(repository_path, tag) }
        end
      end
    end

    def secondary_tags
      strong_memoize(:secondary_tags) do
        container_repository.tags.map do |tag|
          { name: tag.name, digest: tag.digest }
        end
      end
    end

    def tags_to_sync
      primary_tags - secondary_tags
    end

    def tags_to_remove
      secondary_tags - primary_tags
    end

    # The client for primary registry
    def client
      strong_memoize(:client) do
        ContainerRegistry::Client.new(
          Gitlab.config.geo.registry_replication.primary_api_url,
          token: ::Auth::ContainerRegistryAuthenticationService.pull_access_token(repository_path)
        )
      end
    end
  end
end
