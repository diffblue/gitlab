# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        module Locations
          class ContainerScanning < Base
            attr_reader :image
            attr_reader :operating_system
            attr_reader :package_name
            attr_reader :package_version

            def initialize(image:, operating_system:, package_name: nil, package_version: nil, default_branch_image: nil)
              @image = image
              @operating_system = operating_system
              @package_name = package_name
              @package_version = package_version
              @default_branch_image = default_branch_image
            end

            def fingerprint_data
              "#{docker_image_name_without_tag}:#{package_name}"
            end

            def default_branch_image
              return @default_branch_image if Feature.enabled?(:improved_container_scan_matching)
            end

            private

            def docker_image_name_without_tag
              image_name = default_branch_image.presence || image
              base_name, version = image_name.split(':')

              return image if version_semver_like?(version)

              base_name
            end

            def version_semver_like?(version)
              hash_like = /\A[0-9a-f]{32,128}\z/i

              if Gem::Version.correct?(version)
                !hash_like.match?(version)
              else
                false
              end
            end
          end
        end
      end
    end
  end
end
