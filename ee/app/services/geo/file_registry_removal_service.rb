# frozen_string_literal: true

module Geo
  ##
  ## Geo::FileRegistryRemovalService handles blob removal from a secondary node,
  ## the file itself and the database records.
  ## It handles all the possible combinations of 4 variables:
  ## * Whether Model record exists
  ## * Whether Registry Record exists
  ## * Whether the file on a storage exists
  ## * Whether the file_path is passed (RegistryConsistencyWorker doesn't pass one)
  ## In all the cases the best effort should have to be made.
  ##
  class FileRegistryRemovalService < BaseFileService
    include ::Gitlab::Utils::StrongMemoize

    LEASE_TIMEOUT = 8.hours.freeze

    # There is a possibility that the replicable's record does not exist
    # anymore. In this case, you need to pass the file_path parameter
    # explicitly.
    def initialize(object_type, object_db_id, file_path = nil, uploader_class = nil)
      @object_type = object_type.to_sym
      @object_db_id = object_db_id
      @object_file_path = file_path
      @object_uploader_class = uploader_class
    end

    def execute
      log_info('Executing')

      try_obtain_lease do
        log_info('Lease obtained')
        destroy_file
        destroy_registry
        log_info('File & registry removed')
      end
    rescue SystemCallError => e
      log_error('Could not remove file', e.message)
      raise
    end

    private

    def file_registry
      strong_memoize(:file_registry) do
        replicator.registry
      end
    end

    def destroy_file
      if file_path
        if File.exist?(file_path)
          log_info('Unlinking file', file_path: file_path)
          File.unlink(file_path)
        elsif object_storage_enabled?
          log_info('Local file not found. Trying object storage')
          destroy_object_storage_file
        else
          log_error('Unable to unlink file from filesystem, or object storage. A file may be orphaned.', object_type: object_type, object_db_id: object_db_id)
        end
      else
        log_error('Unable to unlink file because file path is unknown. A file may be orphaned.', object_type: object_type, object_db_id: object_db_id)
      end
    end

    def destroy_object_storage_file
      if sync_object_storage_enabled?
        if object_file.nil?
          log_error("Can't find #{object_file_path} in object storage path #{object_storage_config[:remote_directory]}")
        else
          log_info("Removing #{object_file_path} from #{object_storage_config[:remote_directory]}")
          object_file.destroy
        end
      else
        log_info('Skipping file deletion as this secondary node is not allowed to replicate content on Object Storage')
      end
    end

    def destroy_registry
      log_info('Removing file registry', file_registry_id: file_registry.id)

      file_registry.destroy
    end

    def replicator
      strong_memoize(:replicator) do
        Gitlab::Geo::Replicator.for_replicable_params(replicable_name: object_type.to_s, replicable_id: object_db_id)
      rescue NotImplementedError
        nil
      end
    end

    def file_path
      strong_memoize(:file_path) do
        next @object_file_path if @object_file_path

        # When local storage is used, just rely on the existing methods
        next if file_uploader.nil?
        next file_uploader.file.path if file_uploader.object_store == ObjectStorage::Store::LOCAL

        file_uploader.class.absolute_path(file_uploader)
      end
    end

    def file_uploader
      strong_memoize(:file_uploader) do
        next replicator.carrierwave_uploader if replicator
      rescue RuntimeError, NameError, ActiveRecord::RecordNotFound => err
        unless @object_uploader_class.nil?
          next @object_uploader_class.constantize.new(object_type)
        end

        # When cleaning up registries, there are some cases where
        # it's impossible to unlink the file:
        #
        # 1. The replicable record does not exist anymore;
        # 2. The replicable file is stored on Object Storage,
        #    but the node is not configured to use Object Store;
        # 3. Unrecognized replicable type;
        #
        log_error('Could not build uploader', err.message)

        nil
      end
    end

    def lease_key
      "file_registry_removal_service:#{object_type}:#{object_db_id}"
    end

    def sync_object_storage_enabled?
      Gitlab::Geo.current_node.sync_object_storage
    end

    def object_storage_config
      return if file_uploader.nil?

      file_uploader.options.object_store
    end

    def object_storage_enabled?
      return false if object_storage_config.nil?
      return false unless object_storage_config.enabled

      true
    end

    def object_file
      config = object_storage_config[:connection].to_hash.deep_symbolize_keys

      ::Fog::Storage.new(config)
        .directories.new(key: object_storage_config[:remote_directory])
        .files
        .head(object_file_path)
    end

    def object_file_path
      return file_path if file_uploader.nil?

      file_path.delete_prefix("#{file_uploader.root}/")
    end

    def lease_timeout
      LEASE_TIMEOUT
    end
  end
end
