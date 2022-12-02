# frozen_string_literal: true

module EE
  module ProtectedBranches
    module ApiService
      extend ::Gitlab::Utils::Override

      override :protected_branch_params
      def protected_branch_params(with_defaults: true)
        super.tap do |hash|
          hash[:unprotect_access_levels_attributes] = ::ProtectedRefs::AccessLevelParams.new(:unprotect, params, with_defaults: with_defaults).access_levels
        end
      end

      override :attributes
      def attributes
        super.tap do |list|
          if project_or_group.licensed_feature_available?(:code_owner_approval_required)
            list << :code_owner_approval_required
          end
        end
      end
    end
  end
end
