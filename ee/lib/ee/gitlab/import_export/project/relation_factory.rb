# frozen_string_literal: true

module EE
  module Gitlab
    module ImportExport
      module Project
        module RelationFactory
          extend ActiveSupport::Concern

          EE_OVERRIDES = {
            deploy_access_levels: 'ProtectedEnvironments::DeployAccessLevel',
            unprotect_access_levels: 'ProtectedBranch::UnprotectAccessLevel',
            security_setting: 'ProjectSecuritySetting'
          }.freeze

          class_methods do
            extend ::Gitlab::Utils::Override

            override :overrides
            def overrides
              super.merge(EE_OVERRIDES)
            end
          end
        end
      end
    end
  end
end
