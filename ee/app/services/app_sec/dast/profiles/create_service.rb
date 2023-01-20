# frozen_string_literal: true

module AppSec
  module Dast
    module Profiles
      class CreateService < BaseService
        def execute
          return error(_('Insufficient permissions')) unless allowed?

          return error(_('Invalid tags')) unless valid_tags?

          ApplicationRecord.transaction do
            @dast_profile = create_profile
            @schedule = create_schedule(@dast_profile) if params.dig(:dast_profile_schedule, :active)
          end

          create_audit_event(@dast_profile, @schedule)

          if params.fetch(:run_after_create)
            on_demand_scan = create_on_demand_scan(@dast_profile)

            return on_demand_scan if on_demand_scan.error?

            pipeline_url = on_demand_scan.payload.fetch(:pipeline_url)
          end

          ServiceResponse.success(
            payload: {
              dast_profile: @dast_profile,
              pipeline_url: pipeline_url,
              dast_profile_schedule: @schedule
            }
          )
        rescue ActiveRecord::RecordInvalid => err
          ServiceResponse.error(message: err.record.errors.full_messages)
        rescue KeyError => err
          ServiceResponse.error(message: err.message.capitalize)
        end

        private

        def create_profile
          ::Dast::Profile.create!(create_params)
        end

        def create_params
          {
            project: project,
            name: params.fetch(:name),
            description: params.fetch(:description),
            branch_name: params[:branch_name],
            dast_site_profile: dast_site_profile,
            dast_scanner_profile: dast_scanner_profile,
            tags: tags
          }
        end

        def create_schedule(dast_profile)
          ::Dast::ProfileSchedule.create!(
            owner: current_user,
            dast_profile: dast_profile,
            project_id: project.id,
            cadence: dast_profile_schedule[:cadence],
            timezone: dast_profile_schedule[:timezone],
            starts_at: dast_profile_schedule[:starts_at]
          )
        end

        def create_on_demand_scan(dast_profile)
          ::AppSec::Dast::Scans::CreateService.new(
            container: project,
            current_user: current_user,
            params: { dast_profile: dast_profile }
          ).execute
        end

        def allowed?
          project.licensed_feature_available?(:security_on_demand_scans)
        end

        def dast_site_profile
          @dast_site_profile ||= params.fetch(:dast_site_profile)
        end

        def dast_scanner_profile
          @dast_scanner_profile ||= params.fetch(:dast_scanner_profile)
        end

        def dast_profile_schedule
          params[:dast_profile_schedule]
        end

        def create_audit_event(dast_profile, schedule)
          ::Gitlab::Audit::Auditor.audit(
            name: 'dast_profile_create',
            author: current_user,
            scope: project,
            target: dast_profile,
            message: 'Added DAST profile'
          )

          if schedule
            ::Gitlab::Audit::Auditor.audit(
              name: 'dast_profile_schedule_create',
              author: current_user,
              scope: project,
              target: schedule,
              message: 'Added DAST profile schedule'
            )
          end
        end
      end
    end
  end
end
