# frozen_string_literal: true

module AppSec
  module Dast
    module Profiles
      class UpdateService < BaseService
        include Gitlab::Utils::StrongMemoize

        def execute
          return unauthorized unless allowed?
          return error(_('Profile parameter missing')) unless dast_profile

          return error(_('Invalid tags')) unless valid_tags?

          build_auditors!

          ApplicationRecord.transaction do
            dast_profile.update!(update_params)

            update_or_create_schedule! if schedule_input_params
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

        def update_params
          update_params = dast_profile_params
          update_params[:tags] = tags if tag_list?
          update_params
        end

        attr_reader :auditors, :create_schedule_audit

        def allowed?
          project.licensed_feature_available?(:security_on_demand_scans) &&
            can?(current_user, :create_on_demand_dast_scan, project)
        end

        def update_or_create_schedule!
          if schedule
            schedule.update!(schedule_input_params)
          else
            ::Dast::ProfileSchedule.new(
              dast_profile: dast_profile,
              owner: current_user,
              project: project
            ).tap do |dast_schedule|
              dast_schedule.update!(schedule_input_params)
            end

            @create_schedule_audit = true
          end
        end

        def schedule
          dast_profile.dast_profile_schedule
        end

        def success(payload)
          ServiceResponse.success(payload: payload)
        end

        def unauthorized
          error(_('You are not authorized to update this profile'), http_status: 403)
        end

        def dast_profile
          params[:dast_profile]
        end

        def dast_profile_params
          params.slice(:dast_site_profile_id, :dast_scanner_profile_id, :name, :description, :branch_name)
        end

        def schedule_input_params
          @schedule_input_params ||= build_schedule_input_params
        end

        def build_schedule_input_params
          return unless params[:dast_profile_schedule]

          # params[:dast_profile_schedule] is `Types::Dast::ProfileScheduleInputType` object.
          # Using to_h method to convert object into equivalent hash.
          dast_profile_schedule_params = params[:dast_profile_schedule]&.to_h
          dast_profile_schedule_params[:user_id] = current_user.id unless schedule&.owner_valid?
          dast_profile_schedule_params
        end

        def build_auditors!
          @auditors = [
            AppSec::Dast::Profiles::Audit::UpdateService.new(container: project, current_user: current_user, params: {
            dast_profile: dast_profile,
            new_params: dast_profile_params,
            old_params: dast_profile.attributes.symbolize_keys
          })
          ]

          if schedule_input_params && schedule
            @auditors <<
              AppSec::Dast::ProfileSchedules::Audit::UpdateService.new(project: project, current_user: current_user, params: {
                dast_profile_schedule: schedule,
                new_params: schedule_input_params,
                old_params: schedule.attributes.symbolize_keys
              })
          end
        end

        def execute_auditors!
          auditors.map(&:execute)

          if create_schedule_audit
            ::Gitlab::Audit::Auditor.audit(
              name: 'dast_profile_schedule_create',
              author: current_user,
              scope: project,
              target: schedule,
              message: 'Added DAST profile schedule'
            )
          end
        end

        def create_scan(dast_profile)
          ::AppSec::Dast::Scans::CreateService.new(
            container: project,
            current_user: current_user,
            params: { dast_profile: dast_profile }
          ).execute
        end
      end
    end
  end
end
