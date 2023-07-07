# frozen_string_literal: true

module PackageMetadata
  class DataObjectFabricator
    include Enumerable

    def initialize(data_file:, sync_config:)
      @data_file = data_file
      @sync_config = sync_config
    end

    def each
      data_file.each do |data|
        obj = create_object(data)
        yield obj unless obj.nil?
      end
    end

    private

    attr_reader :data_file, :sync_config

    def create_object(data)
      data_object_class.create(data, sync_config.purl_type)
    end

    def data_object_class
      return AdvisoryDataObject if sync_config.advisories?

      license_data_object_class
    end

    def license_data_object_class
      return CompressedPackageDataObject if sync_config.v2?

      DataObject
    end
  end
end
