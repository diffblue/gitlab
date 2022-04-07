# frozen_string_literal: true

module EE
  module Groups
    module FeatureSetting
      extend ActiveSupport::Concern

      EE_FEATURES = %i(wiki).freeze

      prepended do
        set_available_features(EE_FEATURES)

        default_value_for :wiki_access_level, value: Featurable::ENABLED, allows_nil: false
      end
    end
  end
end
