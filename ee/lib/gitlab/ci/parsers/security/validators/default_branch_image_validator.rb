# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        module Validators
          class DefaultBranchImageValidator
            IMAGE_WITHOUT_REVISION_REGEX = /.+?(?=:)/

            def initialize(project)
              @project = project
              @validated_images = {}
            end

            def valid?(image_name)
              return false if image_name.blank?
              return @validated_images[image_name] if @validated_images.key?(image_name)

              @validated_images[image_name] = image_name_exists?(image_name)
            end

            private

            attr_reader :project

            delegate :vulnerability_reads, to: :project

            def image_name_exists?(image_name)
              vulnerability_reads
                .container_scanning
                .with_container_image_starting_with(image_name[IMAGE_WITHOUT_REVISION_REGEX])
                .exists?
            end
          end
        end
      end
    end
  end
end
