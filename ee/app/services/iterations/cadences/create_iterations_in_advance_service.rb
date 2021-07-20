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
        ::Gitlab::Database.bulk_insert(Iteration.table_name, build_new_iterations) # rubocop:disable Gitlab/BulkInsert

        cadence.update!(last_run_date: compute_last_run_date)

        ::ServiceResponse.success
      end

      private

      attr_accessor :user, :cadence

      def build_new_iterations
        new_iterations = []
        new_start_date = new_iteration_start_date
        iteration_number = new_iteration_number

        Iteration.with_group_iid_supply(cadence.group) do |supply|
          1.upto(new_iterations_count) do
            iteration = build_iteration(cadence, new_start_date, iteration_number, supply.next_value)

            new_iterations << iteration

            iteration_number += 1
            new_start_date = iteration[:due_date] + 1.day
          end

          new_iterations
        end
      end

      def build_iteration(cadence, next_start_date, iteration_number, iid)
        current_time = Time.current
        duration = cadence.duration_in_weeks
        # because iteration start and due date are dates and not datetime and
        # we do not allow for dates of 2 iterations to overlap a week ends-up being 6 days.
        # i.e. instead of having something like: 2020-01-01 00:00:00 - 2020-01-08 00:00:00
        # we would convene to have 2020-01-01 00:00:00 - 2020-01-07 23:59:59 and because iteration dates have no time
        # we end up having 2020-01-01(beginning of day) - 2020-01-07(end of day)
        start_date = next_start_date
        due_date = start_date + duration.weeks - 1.day
        title = "Iteration #{iteration_number}: #{format_period(start_date, due_date)}"

        {
          iid: iid,
          iterations_cadence_id: cadence.id,
          created_at: current_time,
          updated_at: current_time,
          group_id: cadence.group_id,
          start_date: start_date,
          due_date: due_date,
          state_enum: Iteration::STATE_ENUM_MAP[::Iteration.compute_state(start_date, due_date)],
          title: title
        }
      end

      def start_date
        @start_date ||= cadence.start_date >= Date.today ? cadence.start_date : Date.today
      end

      def existing_iterations_in_advance
        # we will be allowing up to 10 iterations in advance, so it should be fine to load all in memory
        @existing_iterations_in_advance ||= cadence_iterations.with_start_date_after(start_date).to_a
      end

      def cadence_iterations
        cadence.iterations.due_date_order_asc
      end

      def last_cadence_iteration
        @last_cadence_iteration ||= cadence_iterations.last
      end

      def new_iteration_number
        @new_iteration_number ||= cadence_iterations.count + 1
      end

      def new_iteration_start_date
        strong_memoize(:new_iteration_start_date) do
          last_iteration_due_date = last_cadence_iteration&.due_date
          last_iteration_due_date += 1.day if last_iteration_due_date
          [last_iteration_due_date, cadence.start_date].compact.max
        end
      end

      def new_iterations_count
        strong_memoize(:new_iterations_count) do
          if existing_iterations_in_advance.count == 0
            if cadence.start_date >= Date.today
              cadence.iterations_in_advance
            else
              backfill_iterations_count = ((Date.today - new_iteration_start_date - 1).to_f / (7 * cadence.duration_in_weeks).to_f).ceil
              backfill_iterations_count + cadence.iterations_in_advance
            end
          else
            cadence.iterations_in_advance - existing_iterations_in_advance.count
          end
        end
      end

      def update_existing_iterations!
        return if existing_iterations_in_advance.empty?

        prev_iteration = nil
        duration_before = existing_iterations_in_advance.last.due_date - existing_iterations_in_advance.first.start_date

        existing_iterations_in_advance.each do |iteration|
          if iteration.duration_in_days != cadence.duration_in_days
            old_title_dates_substring = format_period(iteration.start_date, iteration.due_date)
            iteration.start_date = prev_iteration.due_date + 1.day if prev_iteration
            iteration.due_date = iteration.start_date + cadence.duration_in_days.days - 1.day
            new_title_dates_substring = format_period(iteration.start_date, iteration.due_date)
            iteration.title = iteration.title.gsub(old_title_dates_substring, new_title_dates_substring)
          end

          prev_iteration = iteration
        end

        duration_after = existing_iterations_in_advance.last.due_date - existing_iterations_in_advance.first.start_date

        if duration_before > duration_after
          existing_iterations_in_advance.each { |it| it.save! }
        else
          existing_iterations_in_advance.reverse_each { |it| it.save! }
        end
      end

      def format_period(start_date, due_date)
        format = Date::DATE_FORMATS[:long]

        "#{start_date.strftime(format)} - #{due_date.strftime(format)}"
      end

      def compute_last_run_date
        reloaded_last_iteration = cadence_iterations.last
        run_date = reloaded_last_iteration.due_date - ((cadence.iterations_in_advance - 1) * cadence.duration_in_weeks).weeks if reloaded_last_iteration
        run_date ||= Date.today

        run_date
      end

      def can_create_iterations_in_cadence?
        cadence && user && cadence.group.iteration_cadences_feature_flag_enabled? &&
          (user.automation_bot? || user.can?(:create_iteration_cadence, cadence))
      end
    end
  end
end
