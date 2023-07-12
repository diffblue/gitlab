# frozen_string_literal: true

module EE
  module ProjectStatistics
    extend ::Gitlab::Utils::Override

    def cost_factored_storage_size
      (storage_size * cost_factor).round
    end

    private

    def cost_factor
      if project.forked? && (project.root_ancestor.paid? || !project.private?)
        ::Namespaces::Storage::RootSize::COST_FACTOR_FOR_FORKS
      else
        ::Namespaces::Storage::RootSize::COST_FACTOR
      end
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
