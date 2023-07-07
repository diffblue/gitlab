# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module ProjectConfig
        extend ::Gitlab::Utils::Override

        private

        override :sources
        def sources
          # SecurityPolicyDefault should come last. It is only necessary if no other source is available.
          [::Gitlab::Ci::ProjectConfig::Compliance].concat(super)
                                                   .concat([::Gitlab::Ci::ProjectConfig::SecurityPolicyDefault])
        end
      end
    end
  end
end
