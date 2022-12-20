# frozen_string_literal: true

module EE
  module Gitlab
    module ImportExport
      module Project
        module RelationFactory
          extend ActiveSupport::Concern
          extend ::Gitlab::Utils::Override

          EE_OVERRIDES = {
            deploy_access_levels: 'ProtectedEnvironments::DeployAccessLevel',
            unprotect_access_levels: 'ProtectedBranch::UnprotectAccessLevel',
            security_setting: 'ProjectSecuritySetting',
            iterations_cadence: 'Iterations::Cadence',
            approval_rules: 'ApprovalProjectRule',
            approval_project_rules_users: 'ApprovalProjectRulesUser',
            approval_project_rules_protected_branches: 'ApprovalProjectRulesProtectedBranch'
          }.freeze

          EE_EXISTING_OBJECT_RELATIONS = %i[
            iteration
          ].freeze

          class_methods do
            extend ::Gitlab::Utils::Override

            override :overrides
            def overrides
              super.merge(EE_OVERRIDES)
            end

            override :existing_object_relations
            def existing_object_relations
              super + EE_EXISTING_OBJECT_RELATIONS
            end
          end

          override :invalid_relation?
          def invalid_relation?
            super || iteration_relation_without_group?
          end

          override :generate_imported_object
          def generate_imported_object
            imported_object = super

            return if iteration_event_without_iteration?(imported_object)

            imported_object
          end

          # Skip creation of iteration related relations if a project is not imported into a group,
          # as iterations are currently not allowed to be created in a project
          def iteration_relation_without_group?
            %i[resource_iteration_events iteration].include?(relation_name) && importable.group.nil?
          end

          def iteration_event_without_iteration?(object)
            relation_name == :resource_iteration_events && object&.iteration.nil?
          end
        end
      end
    end
  end
end
