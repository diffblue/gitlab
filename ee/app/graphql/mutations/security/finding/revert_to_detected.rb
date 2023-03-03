# frozen_string_literal: true

module Mutations
  module Security
    module Finding
      class RevertToDetected < BaseMutation
        graphql_name 'SecurityFindingRevertToDetected'

        authorize :admin_vulnerability

        field :security_finding,
              ::Types::PipelineSecurityReportFindingType,
              null: true,
              description: 'Finding reverted to detected.'

        argument :uuid,
                 GraphQL::Types::String,
                 required: true,
                 description: 'UUID of the finding to be dismissed.'

        def resolve(uuid:, comment: nil)
          security_finding = authorized_find!(uuid: uuid)
          project = security_finding.project
          vulnerability = security_finding.vulnerability
          dismissal_feedback = security_finding.dismissal_feedback

          result =
            if vulnerability
              ::Vulnerabilities::RevertToDetectedService.new(current_user, vulnerability, comment).execute
            elsif dismissal_feedback # eslif to be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/324899
              VulnerabilityFeedback::DestroyService
              .new(project, current_user, dismissal_feedback, revert_vulnerability_state: false)
              .execute
            end

          {
            security_finding: security_finding.reset,
            errors: result&.errors || []
          }
        end

        private

        def find_object(uuid:)
          # The with_feedbacks and with_pipeline_entities can be removed with
          # https://gitlab.com/gitlab-org/gitlab/-/issues/324899
          ::Security::Finding
            .with_vulnerability
            .with_feedbacks
            .with_pipeline_entities
            .find_by_uuid(uuid)
        end
      end
    end
  end
end
