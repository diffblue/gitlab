# frozen_string_literal: true

module EE
  module Groups
    module FeatureSetting
      extend ActiveSupport::Concern

      EE_FEATURES = %i(wiki).freeze

      prepended do
        set_available_features(EE_FEATURES)

        attribute :wiki_access_level, default: -> { Featurable::ENABLED }

        after_update_commit :maintain_group_wiki_permissions_in_elastic, if: -> {
          group.use_elasticsearch? && ::Wiki.use_separate_indices?
        }

        def wiki_access_level=(value)
          value = ::Groups::FeatureSetting.access_level_from_str(value) if %w[disabled private enabled].include?(value)
          raise ArgumentError, "Invalid wiki_access_level \"#{value}\"" unless %w[0 10 20].include?(value.to_s)

          write_attribute(:wiki_access_level, value)
        end
      end

      private

      def maintain_group_wiki_permissions_in_elastic
        return unless wiki_access_level_previously_changed?

        ElasticWikiIndexerWorker.perform_async(group.id, group.class.name, force: true)
      end
    end
  end
end
