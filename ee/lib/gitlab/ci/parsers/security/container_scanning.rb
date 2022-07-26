# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class ContainerScanning < Common
          include Utils::StrongMemoize

          private

          def create_location(location_data)
            ::Gitlab::Ci::Reports::Security::Locations::ContainerScanning.new(
              image: location_data['image'],
              operating_system: location_data['operating_system'],
              package_name: location_data.dig('dependency', 'package', 'name'),
              package_version: location_data.dig('dependency', 'version'),
              default_branch_image: default_branch_image(location_data),
              default_branch_image_validator: default_branch_image_validator
            )
          end

          def default_branch_image(location_data)
            return if @report.pipeline.default_branch?

            location_data['default_branch_image']
          end

          def default_branch_image_validator
            strong_memoize(:default_branch_image_validator) do
              Validators::DefaultBranchImageValidator.new(@project)
            end
          end
        end
      end
    end
  end
end
