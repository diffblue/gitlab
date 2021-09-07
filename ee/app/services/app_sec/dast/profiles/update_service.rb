# frozen_string_literal: true

module AppSec
  module Dast
    module Profiles
      class UpdateService < BaseContainerService
        include Gitlab::Utils::StrongMemoize

        def execute
          return unauthorized unless allowed?
          return error('Profile parameter missing') unless dast_profile
          return error('Dast Profile Schedule not found') if update_schedule? && !schedule

          build_auditors!

          ApplicationRecord.transaction do
            dast_profile.update!(dast_profile_params)

            update_schedule if update_schedule?
          end

          execute_auditors!

          unless params[:run_after_update]
            return success(
              dast_profile: dast_profile,
              pipeline_url: nil,
              dast_profile_schedule: schedule
            )
          end

          response = create_scan(dast_profile)

          return error(response.message) if response.error?

          success(
            dast_profile: dast_profile,
            pipeline_url: response.payload.fetch(:pipeline_url),
            dast_profile_schedule: schedule
          )
        rescue ActiveRecord::RecordInvalid => err
          error(err.record.errors.full_messages)
        end

        private

        attr_reader :auditors

        def allowed?
          container.licensed_feature_available?(:security_on_demand_scans) &&
            can?(current_user, :create_on_demand_dast_scan, container)
        end

        def update_schedule?
          schedule_input_params.present?
        end

        def update_schedule
          schedule.update!(schedule_input_params)
        end

        def schedule
          @schedule ||= dast_profile.dast_profile_schedule
        end

        def error(message, opts = {})
          ServiceResponse.error(message: message, **opts)
        end

        def success(payload)
          ServiceResponse.success(payload: payload)
        end

        def unauthorized
          error('You are not authorized to update this profile', http_status: 403)
        end

        def dast_profile
          params[:dast_profile]
        end

        def dast_profile_params
          params.slice(:dast_site_profile_id, :dast_scanner_profile_id, :name, :description, :branch_name)
        end

        def schedule_input_params
          # params[:dast_profile_schedule] is `Types::Dast::ProfileScheduleInputType` object.
          # Using to_h method to convert object into equivalent hash.
          @schedule_input_params ||= params[:dast_profile_schedule]&.to_h
        end

        def build_auditors!
          @auditors = [
              AppSec::Dast::Profiles::Audit::UpdateService.new(container: container, current_user: current_user, params: {
              dast_profile: dast_profile,
              new_params: dast_profile_params,
              old_params: dast_profile.attributes.symbolize_keys
            })
          ]

          if schedule_input_params
            @auditors <<
              AppSec::Dast::ProfileSchedules::Audit::UpdateService.new(project: container, current_user: current_user, params: {
                dast_profile_schedule: schedule,
                new_params: schedule_input_params,
                old_params: schedule.attributes.symbolize_keys
              })
          end
        end

        def execute_auditors!
          auditors.map(&:execute)
        end

        def create_scan(dast_profile)
          ::DastOnDemandScans::CreateService.new(
            container: container,
            current_user: current_user,
            params: { dast_profile: dast_profile }
          ).execute
        end
      end
    end
  end
end
