# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module ProjectConfig
        extend ::Gitlab::Utils::Override

        EE_SOURCES = [::Gitlab::Ci::ProjectConfig::Compliance].freeze

        private

        override :sources
        def sources
          EE_SOURCES + super
        end
      end
    end
  end
end
