# frozen_string_literal: true

module EE
  module ProtectedBranches
    module ApiService
      extend ::Gitlab::Utils::Override

      override :protected_branch_params
      def protected_branch_params
        super.tap do |hash|
          hash[:unprotect_access_levels_attributes] = ::ProtectedRefs::AccessLevelParams.new(:unprotect, params).access_levels
          hash[:code_owner_approval_required] = code_owner_approval_required?
        end
      end

      def code_owner_approval_required?
        if project.code_owner_approval_required_available?
          params[:code_owner_approval_required] || false
        else
          false
        end
      end
    end
  end
end
