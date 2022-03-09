# frozen_string_literal: true

module IncidentManagement
  module OncallShifts
    class ReadService < ::BaseProjectService
      MAXIMUM_TIMEFRAME = 1.month

      # @param rotation [IncidentManagement::OncallRotation]
      # @param current_user [User]
      # @param params [Hash<Symbol,Any>]
      # @option params - start_time [Time]
      # @option params - end_time [Time]
      def initialize(rotation, current_user, start_time:, end_time:)
        super(project: rotation.project, current_user: current_user)

        @rotation = rotation
        @start_time = start_time
        @end_time = end_time
        @current_time = Time.current
      end

      def execute
        return error_no_license unless available?
        return error_no_permissions unless allowed?
        return error_invalid_range unless start_before_end?
        return error_excessive_range unless under_max_timeframe?

        persisted_shifts = find_shifts
        generated_shifts = generate_shifts
        shifts = combine_shifts(persisted_shifts, generated_shifts)

        success(shifts)
      end

      private

      attr_reader :rotation, :start_time, :end_time, :current_time

      def find_shifts
        rotation
          .shifts
          .for_timeframe(start_time, [end_time, current_time].min)
          .order_starts_at_desc
      end

      def generate_shifts
        ::IncidentManagement::OncallShiftGenerator
          .new(rotation)
          .for_timeframe(
            starts_at: [start_time, current_time].max,
            ends_at: end_time
          )
      end

      def combine_shifts(persisted_shifts, generated_shifts)
        return generated_shifts unless persisted_shifts.present?

        # Remove duplicate or overlapping shifts
        min_start_time = persisted_shifts.last.ends_at
        generated_shifts.reject! { |shift| shift.starts_at < min_start_time }

        persisted_shifts + generated_shifts
      end

      def available?
        ::Gitlab::IncidentManagement.oncall_schedules_available?(project)
      end

      def allowed?
        Ability.allowed?(current_user, :read_incident_management_oncall_schedule, rotation)
      end

      def start_before_end?
        start_time < end_time
      end

      def under_max_timeframe?
        end_time.to_date <= start_time.to_date + MAXIMUM_TIMEFRAME
      end

      def error(message)
        ServiceResponse.error(message: message)
      end

      def success(shifts)
        ServiceResponse.success(payload: { shifts: shifts })
      end

      def error_no_permissions
        error(_('You have insufficient permissions to view shifts for this rotation'))
      end

      def error_no_license
        error(_('Your license does not support on-call rotations'))
      end

      def error_invalid_range
        error(_('`start_time` should precede `end_time`'))
      end

      def error_excessive_range
        error(_('`end_time` should not exceed one month after `start_time`'))
      end
    end
  end
end
