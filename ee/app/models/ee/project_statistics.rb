# frozen_string_literal: true

module EE
  module ProjectStatistics
    extend ::Gitlab::Utils::Override

    def cost_factored_storage_size
      (storage_size * cost_factor).round
    end

    private

    def cost_factor
      ::Namespaces::Storage::CostFactor.cost_factor_for(project)
    end

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
