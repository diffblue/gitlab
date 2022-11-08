# frozen_string_literal: true

module EE
  module Groups
    module FeatureSetting
      extend ActiveSupport::Concern

      EE_FEATURES = %i(wiki).freeze

      prepended do
        set_available_features(EE_FEATURES)

        attribute :wiki_access_level, default: -> { Featurable::ENABLED }
      end
    end
  end
end
