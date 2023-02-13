# frozen_string_literal: true

module EE
  module API
    module Releases
      extend ActiveSupport::Concern

      prepended do
        resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          desc 'Collect release evidence' do
            detail 'Creates an evidence for an existing Release. This feature was introduced in GitLab 12.10.'
            success ::API::Entities::Release
            failure [
              { code: 401, message: 'Unauthorized' },
              { code: 404, message: 'Not found' }
            ]
            tags %w[releases]
          end
          params do
            requires :tag_name, type: String, desc: 'The Git tag the release is associated with', as: :tag
          end
          route_setting :authentication, job_token_allowed: true
          post ':id/releases/:tag_name/evidence', requirements: ::API::Releases::RELEASE_ENDPOINT_REQUIREMENTS do
            authorize_create_evidence!

            if release.present?
              params = { tag: release.tag }
              evidence_pipeline = ::Releases::EvidencePipelineFinder.new(release.project, params).execute
              ::Releases::CreateEvidenceWorker.perform_async(release.id, evidence_pipeline)

              status :accepted
            else
              status :not_found
            end
          end
        end

        helpers do
          extend ::Gitlab::Utils::Override

          override :log_release_created_audit_event
          def log_release_created_audit_event(release)
            message = "Created Release #{release.tag}"
            if release.milestones.count > 0
              message += " with #{'Milestone'.pluralize(release.milestones.count)} " +
                release.milestone_titles
            end

            audit_context = {
              name: 'release_created',
              ip_address: request.ip,
              author: current_user,
              target: release,
              scope: user_project,
              message: message,
              target_details: release.name
            }

            ::Gitlab::Audit::Auditor.audit(audit_context)
          end

          override :log_release_updated_audit_event
          def log_release_updated_audit_event
            audit_context = {
              name: 'release_updated',
              ip_address: request.ip,
              author: current_user,
              target: release,
              scope: user_project,
              message: "Updated Release #{release.tag}",
              target_details: release.name
            }

            ::Gitlab::Audit::Auditor.audit(audit_context)
          end

          override :log_release_deleted_audit_event
          def log_release_deleted_audit_event
            audit_context = {
              name: 'release_deleted_audit_event',
              ip_address: request.ip,
              author: current_user,
              target: release,
              scope: user_project,
              message: "Deleted release #{release.tag}",
              target_details: release.name
            }

            ::Gitlab::Audit::Auditor.audit(audit_context)
          end

          override :log_release_milestones_updated_audit_event
          def log_release_milestones_updated_audit_event
            milestones = release.milestone_titles.presence || '[none]'

            audit_context = {
              name: 'release_milestones_updated',
              ip_address: request.ip,
              author: current_user,
              target: release,
              scope: user_project,
              message: "Milestones associated with release changed to #{milestones}",
              target_details: release.name
            }

            ::Gitlab::Audit::Auditor.audit(audit_context)
          end

          override :authorize_create_evidence!
          def authorize_create_evidence!
            authorize_create_release!
          end
        end
      end
    end
  end
end
