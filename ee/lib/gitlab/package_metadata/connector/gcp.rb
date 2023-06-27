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
      class Gcp < BaseConnector
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

        # gcp file_prefix has a trailing slash, so the base connector definition
        # is updated to add the trailing slash.
        def file_prefix
          File.join(super, '')
        end

        def all_files
          bucket.files(prefix: file_prefix).all.lazy.map do |file|
            sequence, chunk = sequence_and_chunk_from(file.name)

            data_file_class.new(GcpFileWrapper.new(file), sequence, chunk)
          end
        end

        def bucket
          connection.bucket(sync_config.base_uri, skip_lookup: true)
        end

        def connection
          @connection ||= Google::Cloud::Storage.anonymous
        end

        # GcpFileWrapper ensures that #download is only called on the gcp file when caller needs to access the data.
        class GcpFileWrapper
          def initialize(gcp_file)
            @gcp_file = gcp_file
          end

          def each_line(&block)
            io.each_line(&block)
          end

          private

          def io
            @io ||= @gcp_file.download(skip_decompress: true)
          end
        end
      end
    end
  end
end
