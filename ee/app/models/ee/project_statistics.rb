# frozen_string_literal: true

module EE
  module ProjectStatistics
    extend ::Gitlab::Utils::Override

    private

    override :storage_size_components
    def storage_size_components
      if ::Gitlab::CurrentSettings.should_check_namespace_plan?
        self.class::STORAGE_SIZE_COMPONENTS - [:uploads_size]
      else
        super
      end
    end
  end
end
