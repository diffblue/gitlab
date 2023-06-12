# frozen_string_literal: true

module ComplianceManagement
  module Standards
    module Gitlab
      class PreventApprovalByAuthorService < BaseService
        CHECK_NAME = :prevent_approval_by_merge_request_author

        def execute
          return project_not_found if project.blank?

          create_or_update_project_adherence
        end

        private

        def create_or_update_project_adherence
          attributes = {
            project_id: project.id,
            namespace_id: project.namespace_id,
            status: status(project.merge_requests_author_approval?),
            check_name: CHECK_NAME,
            standard: STANDARD
          }

          project_adherence = ::Projects::ComplianceStandards::Adherence
                                .for_project(project)
                                .for_check_name(CHECK_NAME)
                                .for_standard(STANDARD)
                                .first

          project_adherence = ::Projects::ComplianceStandards::Adherence.new if project_adherence.blank?

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
      end
    end
  end
end
