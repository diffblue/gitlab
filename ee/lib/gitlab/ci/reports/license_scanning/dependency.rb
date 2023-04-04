# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module LicenseScanning
        class Dependency
          attr_accessor :path
          attr_reader :name, :package_manager, :purl_type, :version

          def initialize(attributes = {})
            @name = attributes.fetch(:name)
            @package_manager = attributes[:package_manager]
            @path = attributes[:path]
            @purl_type = attributes[:purl_type]
            @version = attributes[:version]
          end

          def blob_path_for(project, sha: project&.default_branch_or_main)
            return if path.blank?
            return path if sha.blank?

            ::Gitlab::Routing
              .url_helpers
              .project_blob_path(project, File.join(sha, path))
          end

          def eql?(other)
            name == other.name &&
              package_manager == other.package_manager &&
              purl_type == other.purl_type &&
              version == other.version
          end

          def hash
            [name, package_manager, purl_type, version].hash
          end
        end
      end
    end
  end
end
