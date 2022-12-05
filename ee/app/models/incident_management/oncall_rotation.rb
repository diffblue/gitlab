# frozen_string_literal: true

module IncidentManagement
  class OncallRotation < ApplicationRecord
    include EachBatch

    ActivePeriod = Struct.new(:start_time, :end_time) do
      def present?
        start_time && end_time
      end

      def end_after_start?
        end_time > start_time if present?
      end

      def for_date(start_date)
        end_date = end_after_start? ? start_date : start_date.next_day

        [
          start_date.change(hour: start_time.hour, min: start_time.min),
          end_date.change(hour: end_time.hour, min: end_time.min)
        ]
      end
    end

    self.table_name = 'incident_management_oncall_rotations'

    enum length_unit: {
      hours: 0,
      days: 1,
      weeks: 2
    }

    NAME_LENGTH = 200

    belongs_to :schedule, class_name: 'OncallSchedule', inverse_of: 'rotations', foreign_key: 'oncall_schedule_id'
    has_many :participants, -> { order(id: :asc) }, class_name: 'OncallParticipant', inverse_of: :rotation
    # Note! If changing the order of participants, also change the :with_shift_generation_associations scope.
    has_many :active_participants, -> { not_removed.order(id: :asc) }, class_name: 'OncallParticipant', inverse_of: :rotation
    has_many :users, through: :participants
    has_many :participating_users, through: :active_participants, source: :user
    has_many :shifts, class_name: 'OncallShift', inverse_of: :rotation, foreign_key: :rotation_id

    validates :name, presence: true, uniqueness: { scope: :oncall_schedule_id }, length: { maximum: NAME_LENGTH }
    validates :starts_at, presence: true
    validates :length, presence: true, numericality: true
    validates :length_unit, presence: true
    validate :valid_ends_at, if: -> { ends_at && starts_at }

    validates :active_period_start, presence: true, if: :active_period_end
    validates :active_period_end, presence: true, if: :active_period_start
    validate :no_active_period_for_hourly_shifts, if: :hours?

    scope :for_project, -> (project) { joins(:schedule).merge(OncallSchedule.for_project(project)) }
    scope :in_progress, -> { where('starts_at < :time AND (ends_at > :time OR ends_at IS NULL)', time: Time.current) }
    scope :except_ids, -> (ids) { where.not(id: ids) }
    scope :with_active_period, -> { where.not(active_period_start: nil) }
    scope :with_shift_generation_associations, -> do
      joins(:active_participants, :schedule)
        .distinct
        .includes(:active_participants, :schedule)
        .order(:id, 'incident_management_oncall_participants.id ASC')
    end

    delegate :project, to: :schedule

    def self.pluck_id_and_user_id
      joins(shifts: { participant: :user }).pluck(:id, 'users.id')
    end

    # The duration of a shift cycle, which is the time until the next participant is on-call.
    # If a shift active period is setup then many shifts will be within a shift_cycle_duration.
    def shift_cycle_duration
      # As length_unit is an enum, input is guaranteed to be appropriate
      length.public_send(length_unit) # rubocop:disable GitlabSecurity/PublicSend
    end

    # If there is an active period, and the rotation unit is weeks, we multiple the
    # count of shifts per cycle by 7, as there are 7 days in a week.
    def shifts_per_cycle
      return 1 unless has_shift_active_period?

      weeks? ? (7 * length) : length
    end

    def active_period
      ActivePeriod.new(active_period_start, active_period_end)
    end

    def has_shift_active_period?
      !hours? && active_period.present?
    end

    def upsert_participants!(new_participants)
      ::IncidentManagement::OncallParticipant.upsert_all(
        new_participants,
        unique_by: :index_inc_mgmnt_oncall_participants_on_user_id_and_rotation_id
      )
    end

    private

    def valid_ends_at
      errors.add(:ends_at, _('must be after start')) if ends_at <= starts_at
    end

    def no_active_period_for_hourly_shifts
      if active_period_start || active_period_end
        errors.add(:length_unit, _('Restricted shift times are not available for hourly shifts'))
      end
    end
  end
end
