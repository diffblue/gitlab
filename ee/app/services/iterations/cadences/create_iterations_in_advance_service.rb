# frozen_string_literal: true

module Iterations
  module Cadences
    class CreateIterationsInAdvanceService
      include Gitlab::Utils::StrongMemoize

      def initialize(user, cadence)
        @user = user
        @cadence = cadence
      end

      def execute
        return ::ServiceResponse.error(message: _('Operation not allowed'), http_status: 403) unless can_create_iterations_in_cadence?
        return ::ServiceResponse.error(message: _('Cadence is not automated'), http_status: 422) unless cadence.can_be_automated?

        update_existing_iterations!

        Iteration.transaction do
          ::ApplicationRecord.legacy_bulk_insert(Iteration.table_name, build_new_iterations) # rubocop:disable Gitlab/BulkInsert
          cadence.update_iteration_sequences
        end

        cadence.update!(next_run_date: compute_next_run_date)

        ::ServiceResponse.success
      end

      private

      attr_accessor :user, :cadence

      def build_new_iterations
        new_iterations = []
        new_start_date, schedule_count = cadence.next_schedule_date_and_count

        Iteration.with_group_iid_supply(cadence.group) do |supply|
          1.upto(schedule_count) do
            iteration = build_iteration(cadence, new_start_date, supply.next_value)

            new_iterations << iteration

            new_start_date = iteration[:due_date] + 1.day
          end

          new_iterations
        end
      end

      def build_iteration(cadence, next_start_date, iid)
        current_time = Time.current
        duration = cadence.duration_in_weeks
        # because iteration start and due date are dates and not datetime and
        # we do not allow for dates of 2 iterations to overlap a week ends-up being 6 days.
        # i.e. instead of having something like: 2020-01-01 00:00:00 - 2020-01-08 00:00:00
        # we would convene to have 2020-01-01 00:00:00 - 2020-01-07 23:59:59 and because iteration dates have no time
        # we end up having 2020-01-01(beginning of day) - 2020-01-07(end of day)
        start_date = next_start_date
        due_date = start_date + duration.weeks - 1.day

        {
          iid: iid,
          iterations_cadence_id: cadence.id,
          created_at: current_time,
          updated_at: current_time,
          group_id: cadence.group_id,
          start_date: start_date,
          due_date: due_date,
          state_enum: Iteration::STATE_ENUM_MAP[::Iteration.compute_state(start_date, due_date)]
        }
      end

      def existing_iterations_in_advance
        # we will be allowing up to 10 iterations in advance, so it should be fine to load all in memory
        @existing_iterations_in_advance ||= cadence_iterations.with_start_date_after(Date.current).to_a
      end

      def cadence_iterations
        cadence.iterations.due_date_order_asc
      end

      def last_cadence_iteration
        @last_cadence_iteration ||= cadence_iterations.last
      end

      def update_existing_iterations!
        return if existing_iterations_in_advance.empty?

        next_start_date = cadence.next_open_iteration_start_date

        existing_iterations_in_advance.each do |iteration|
          iteration.start_date = next_start_date
          iteration.due_date = iteration.start_date + cadence.duration_in_days.days - 1.day
          iteration.set_iteration_state

          next_start_date = iteration.due_date + 1.day
        end

        cadence.transaction do
          existing_iterations_in_advance.each do |it|
            it.update_columns({ state_enum: it.state_enum, start_date: it.start_date, due_date: it.due_date })
          end
        end
      end

      def compute_next_run_date
        reloaded_last_iteration = cadence_iterations.last
        run_date = reloaded_last_iteration.start_date - ((cadence.iterations_in_advance - 1) * cadence.duration_in_weeks).weeks if reloaded_last_iteration
        run_date ||= Date.today

        run_date
      end

      def can_create_iterations_in_cadence?
        cadence && user &&
          (user.automation_bot? || user.can?(:create_iteration, cadence))
      end
    end
  end
end
