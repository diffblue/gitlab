# frozen_string_literal: true

module EE
  module Mutations
    module Ci
      module ProjectCiCdSettingsUpdate
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          argument :merge_pipelines_enabled, GraphQL::Types::Boolean,
            required: false,
            description: 'Indicates if merge pipelines are enabled for the project.'

          argument :merge_trains_enabled, GraphQL::Types::Boolean,
            required: false,
            description: 'Indicates if merge trains are enabled for the project.'

          argument :merge_trains_skip_train_allowed, GraphQL::Types::Boolean,
            required: false,
            description: 'Indicates whether an option is allowed to merge without refreshing the merge train. ' \
                         'Ignored unless the `merge_trains_skip_train` feature flag is also enabled.'
        end

        override :resolve
        def resolve(full_path:, **args)
          if ::Feature.disabled?(:merge_trains_skip_train, project(full_path))
            args.delete(:merge_trains_skip_train_allowed)
          end

          super.tap do |result|
            ci_cd_settings = result[:ci_cd_settings]
            audit_project = ci_cd_settings.project

            if ci_cd_settings.inbound_job_token_scope_enabled_previously_changed?
              audit(audit_project, ci_cd_settings, current_user, ci_cd_settings.inbound_job_token_scope_enabled)
            end
          end
        end

        private

        def audit(scope, target, author, inbound_job_token_scope_enabled)
          audit_action = inbound_job_token_scope_enabled ? 'enabled' : 'disabled'
          audit_message = "Secure ci_job_token was #{audit_action} for inbound"
          event_name = "secure_ci_job_token_inbound_#{audit_action}"

          audit_context = {
            name: event_name,
            author: author,
            scope: scope,
            target: target,
            message: audit_message
          }

          ::Gitlab::Audit::Auditor.audit(audit_context)
        end
      end
    end
  end
end
