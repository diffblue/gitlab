# frozen_string_literal: true

require 'tempfile'

module Geo
  class ContainerRepositorySync
    include Gitlab::Utils::StrongMemoize

    FOREIGN_MEDIA_TYPE = 'application/vnd.docker.image.rootfs.foreign.diff.tar.gzip'

    # Manifests that reference other manifests (fat manifests)
    LIST_MANIFESTS = [
      ContainerRegistry::Client::DOCKER_DISTRIBUTION_MANIFEST_LIST_V2_TYPE,
      ContainerRegistry::Client::OCI_DISTRIBUTION_INDEX_TYPE
    ].freeze

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

      if LIST_MANIFESTS.include? manifest_parsed['mediaType']
        if buildkit_oci_incompatible_index?(manifest_parsed['manifests'])
          sync_manifest_blobs(manifest_parsed)
        else
          manifest_parsed['manifests'].each do |submanifest_ref|
            submanifest_raw = client.repository_raw_manifest(repository_path, submanifest_ref['digest'])
            submanifest_parsed = Gitlab::Json.parse(submanifest_raw)
            sync_manifest_blobs(submanifest_parsed)

            container_repository.push_manifest(
              submanifest_ref['digest'],
              submanifest_raw,
              submanifest_parsed['mediaType']
            )
          end
        end
      else
        sync_manifest_blobs(manifest_parsed)
      end

      # According to OCI specification the mediaType parameter can be left empty or be set
      # to 'application/vnd.oci.image.manifest.v1+json' value.
      # https://github.com/opencontainers/image-spec/blob/main/manifest.md#image-manifest-property-descriptions
      # However, Docker Registry expects the 'Content-Type' header to be always set
      manifest_media_type = manifest_parsed['mediaType'] || ContainerRegistry::Client::OCI_MANIFEST_V1_TYPE
      container_repository.push_manifest(tag[:name], manifest, manifest_media_type)
    end

    # Buildkit-cache images have special oci-spec-invalid structure where fat manifests reference
    # blobs directly. Normal OCI fat manifest only references other manifests
    # Issue https://github.com/moby/buildkit/issues/2251
    def buildkit_oci_incompatible_index?(manifests)
      manifests.any? do |manifest|
        manifest['mediaType'].include?('application/vnd.buildkit.cacheconfig')
      end
    end

    def sync_manifest_blobs(manifest)
      list_blobs(manifest).each do |digest|
        sync_blob(digest)
      end
    end

    def sync_blob(digest)
      return if container_repository.blob_exists?(digest)

      blob_io, size = client.pull_blob(repository_path, digest)
      container_repository.push_blob(digest, blob_io, size)
    end

    def remove_tag(tag)
      container_repository.delete_tag_by_digest(tag[:digest])
    end

    # Lists blobs or nested manifests
    # manifest['manifests'] is solely used by buildcache here because
    # normal image indexes only refer to other manifests, not blobs
    # manifest['blobs'] references the OCI artifacts
    def list_blobs(manifest)
      blobs = (manifest['layers'] || manifest['manifests'] || manifest['blobs']).filter_map do |blob|
        blob['digest'] unless foreign_layer?(blob)
      end

      blobs.push(manifest.dig('config', 'digest')).compact
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
      strong_memoize_with_expiration(:client, ContainerRepository.registry_client_expiration_time) do
        ContainerRegistry::Client.new(
          Gitlab.config.geo.registry_replication.primary_api_url,
          token: ::Auth::ContainerRegistryAuthenticationService.pull_access_token(repository_path)
        )
      end
    end
  end
end
