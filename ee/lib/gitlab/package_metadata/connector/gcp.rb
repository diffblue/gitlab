# frozen_string_literal: true

require 'google/apis/storage_v1'
require 'google/cloud/storage'

# Package metadata is stored in a gcp bucket in the following format:
#   <version_format>/<package_registry>/<sequence>/<chunk>.csv
#   Example:
#   .
#   - v1
#     - rubygems
#       - 1673033866
#         - 00000001.csv
#         - 00000002.csv
#       - 1673033900
#         - 00000001.csv
#       - 1673045259
#         - 00000001.csv
#         - 00000002.csv
#         - 00000003.csv
#   - v1
#     - pypi
#       - 1683033866
#         - 00000001.csv
#         - 00000002.csv
#
# This class processes gcp files under the <version_format>/<package_registry>
# prefix and yields lines triples of [<package>, <version>, <license>] to the
# caller.
#
# To reduce the amount of data transferred the connector allows the
# caller to ask for gcp files after <sequence> and <chunk>.
module Gitlab
  module PackageMetadata
    module Connector
      class Gcp
        def initialize(bucket_name, version_format, purl_type)
          @bucket_name = bucket_name
          @purl_type = purl_type

          registry_id = ::PackageMetadata::SyncConfiguration.registry_id(purl_type)
          @file_prefix = "#{version_format}/#{registry_id}/"
        end

        def data_after(checkpoint)
          return all_files if checkpoint.blank?

          found_list = all_files.drop_while do |file|
            !file.checkpoint?(checkpoint)
          end

          if found_list.any?
            found_list.drop(1)
          else
            all_files
          end
        end

        private

        attr_reader :bucket_name, :file_prefix, :purl_type

        class CsvFile
          include Enumerable

          attr_reader :sequence, :chunk, :purl_type

          def initialize(file, file_prefix, purl_type)
            @file = file
            @sequence, @chunk = file.name.delete_prefix(file_prefix).delete_suffix('.csv').split('/').map(&:to_i)
            @purl_type = purl_type
          end

          def each(&blk)
            @file.download(skip_decompress: true).each_line do |line|
              data_object = ::PackageMetadata::DataObject.from_csv(line, purl_type)

              yield data_object if data_object
            end
          end

          def checkpoint?(checkpoint)
            sequence == checkpoint.sequence && chunk == checkpoint.chunk
          end
        end

        def all_files
          bucket.files(prefix: file_prefix).all.lazy.map { |file| CsvFile.new(file, file_prefix, purl_type) }
        end

        def bucket
          connection.bucket(bucket_name, skip_lookup: true)
        end

        def connection
          @connection ||= Google::Cloud::Storage.anonymous
        end
      end
    end
  end
end
