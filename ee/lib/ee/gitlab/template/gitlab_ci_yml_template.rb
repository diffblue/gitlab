# frozen_string_literal: true

module EE
  module Gitlab
    module Template
      module GitlabCiYmlTemplate
        extend ActiveSupport::Concern

        EE_TEMPLATES_WITH_LATEST_VERSION = {}.freeze

        class_methods do
          extend ::Gitlab::Utils::Override

          override :categories
          def categories
            super.merge(categories_ee)
          end

          override :additional_excluded_patterns
          def additional_excluded_patterns
            []
          end

          private

          def categories_ee
            {
              'Security' => 'Security'
            }
          end

          override :templates_with_latest_version
          def templates_with_latest_version
            @templates_with_latest_version ||=
              super.merge(EE_TEMPLATES_WITH_LATEST_VERSION)
          end
        end
      end
    end
  end
end
