# frozen_string_literal: true

module API
  module Internal
    module AppSec
      module Dast
        class SiteValidations < ::API::Base
          before do
            authenticate!
            validate_job_token_used!
          end

          feature_category :dynamic_application_security_testing

          namespace :internal do
            namespace :dast do
              resource :site_validations do
                desc 'Transitions a DAST site validation to a new state.' do
                  detail 'This feature is gated by the :dast_runner_site_validation feature flag.'
                end
                route_setting :authentication, job_token_allowed: true
                params do
                  requires :event, type: Symbol, values: %i[start fail_op retry pass], desc: 'The transition event.'
                end
                post ':id/transition' do
                  validation = DastSiteValidation.find(params[:id])

                  unless Feature.enabled?(:dast_runner_site_validation, validation.project, default_enabled: :yaml)
                    render_api_error!('404 Feature flag disabled: :dast_runner_site_validation', 404)
                  end

                  authorize!(:create_on_demand_dast_scan, validation)
                  bad_request!('Project mismatch') unless current_authenticated_job.project == validation.project

                  success = case params[:event]
                            when :start
                              validation.start
                            when :fail_op
                              validation.fail_op
                            when :retry
                              validation.retry
                            when :pass
                              validation.pass
                            end

                  bad_request!('Could not update DAST site validation') unless success

                  status 200

                  { state: validation.state }
                end
              end
            end
          end

          helpers do
            def validate_job_token_used!
              bad_request!('Must authenticate using job token') unless current_authenticated_job
            end
          end
        end
      end
    end
  end
end
