# frozen_string_literal: true

module EE
  module LabelLink
    extend ActiveSupport::Concern

    LABEL_INDEXED_MODELS = %w[Issue].freeze

    prepended do
      after_destroy :maintain_target_elasticsearch!
    end

    private

    def maintain_target_elasticsearch!
      object = target
      return if LABEL_INDEXED_MODELS.exclude?(object.class.name)

      Elastic::ProcessBookkeepingService.track!(object)
    end
  end
end
