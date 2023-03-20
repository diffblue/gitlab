# frozen_string_literal: true

module EE
  module Groups
    module FeatureSetting
      extend ActiveSupport::Concern

      EE_FEATURES = %i(wiki).freeze

      prepended do
        set_available_features(EE_FEATURES)

        attribute :wiki_access_level, default: -> { Featurable::ENABLED }

        def wiki_access_level=(value)
          value = ::Groups::FeatureSetting.access_level_from_str(value) if %w[disabled private enabled].include?(value)
          raise ArgumentError, "Invalid wiki_access_level \"#{value}\"" unless %w[0 10 20].include?(value.to_s)

          write_attribute(:wiki_access_level, value)
        end
      end
    end
  end
end
