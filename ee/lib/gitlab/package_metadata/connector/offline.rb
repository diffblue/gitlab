# frozen_string_literal: true

module Gitlab
  module PackageMetadata
    module Connector
      class Offline
        def initialize(bucket_name, version_format, purl_type)
          @bucket_name = bucket_name
          @file_prefix = "#{version_format}/#{purl_type}/"
          @purl_type = purl_type
        end

        def data_after(checkpoint)
          raise NoMethodError, 'offline connector implemented in #384047'
        end
      end
    end
  end
end
