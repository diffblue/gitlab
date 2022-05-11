# frozen_string_literal: true

module EE
  # NamespaceCiCdSetting EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `NamespaceCiCdSetting` model
  module NamespaceCiCdSetting
    extend ActiveSupport::Concern

    prepended do
      include EachBatch

      scope :allowing_stale_runner_pruning, -> do
        where(allow_stale_runner_pruning: true)
      end
    end
  end
end
