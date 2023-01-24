# frozen_string_literal: true

module EE
  module Todo
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include UsageStatistics
    end
  end
end
