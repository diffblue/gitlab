# frozen_string_literal: true

module ComplianceManagement
  module Standards
    module Gitlab
      class PreventApprovalByAuthorService < BaseService
        CHECK_NAME = :prevent_approval_by_merge_request_author

        def execute
          return unavailable_for_user_namespace if project.namespace.user_namespace?

          return feature_not_available unless feature_available?

          create_or_update_project_adherence
        end

        private

        def create_or_update_project_adherence
          project_adherence = find_or_initialize_adherence

          project_adherence.update!(attributes)

          ServiceResponse.success(payload: { compliance_standards_adherence: project_adherence })
        rescue ActiveRecord::RecordInvalid => invalid
          # Handle race condition if two instances of this service were executed at the same time.
          # In such cases both of them might not find records, however, one of them will error out while creating.
          retry if invalid.record&.errors&.of_kind?(:project, :taken)

          ServiceResponse.error(message: invalid.record&.errors&.full_messages&.join(', '))
        end

        def status(is_mr_author_allowed_to_merge)
          is_mr_author_allowed_to_merge ? :fail : :success
        end

        def feature_available?
          project_group.licensed_feature_available?(:group_level_compliance_dashboard)
        end

        def find_or_initialize_adherence
          ::Projects::ComplianceStandards::AdherenceFinder.new(
            project_group,
            current_user,
            { project_ids: project.id, check_name: CHECK_NAME, standard: STANDARD, skip_authorization: true }
          ).execute.first || ::Projects::ComplianceStandards::Adherence.new
        end

        def attributes
          {
            project_id: project.id,
            namespace_id: project.namespace_id,
            status: status(project.merge_requests_author_approval?),
            check_name: CHECK_NAME,
            standard: STANDARD
          }
        end
      end
    end
  end
end
