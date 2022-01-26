# frozen_string_literal: true

module Iterations
  class Cadence < ApplicationRecord
    include Gitlab::SQL::Pattern
    include EachBatch

    self.table_name = 'iterations_cadences'

    ITERATIONS_AUTOMATION_FIELDS = [:duration_in_weeks, :iterations_in_advance].freeze

    belongs_to :group
    has_many :iterations, foreign_key: :iterations_cadence_id, inverse_of: :iterations_cadence

    validates :title, presence: true
    validates :start_date, presence: true, if: :automatic?
    validates :group_id, presence: true
    validates :duration_in_weeks, inclusion: { in: 0..4 }, allow_nil: true
    validates :duration_in_weeks, presence: true, if: :automatic?
    validates :iterations_in_advance, inclusion: { in: 0..10 }, allow_nil: true
    validates :iterations_in_advance, presence: true, if: :automatic?
    validates :active, inclusion: [true, false]
    validates :automatic, inclusion: [true, false]
    validates :description, length: { maximum: 5000 }

    after_commit :ensure_iterations_in_advance, on: [:create, :update], if: :changed_iterations_automation_fields?

    scope :with_groups, -> (group_ids) { where(group_id: group_ids) }
    scope :with_duration, -> (duration) { where(duration_in_weeks: duration) }
    scope :is_automatic, -> (automatic) { where(automatic: automatic) }
    scope :is_active, -> (active) { where(active: active) }
    scope :ordered_by_title, -> { order(:title) }
    scope :for_automated_iterations, -> do
      is_automatic(true)
        .where('duration_in_weeks > 0')
        .where("DATE ((COALESCE(iterations_cadences.last_run_date, DATE('01-01-1970')) + iterations_cadences.duration_in_weeks * INTERVAL '1 week')) <= CURRENT_DATE")
    end

    class << self
      def search_title(query)
        fuzzy_search(query, [::Resolvers::IterationsResolver::DEFAULT_IN_FIELD], use_minimum_char_limit: contains_digit?(query))
      end

      private

      def contains_digit?(query)
        !(query =~ / \d+ /).nil?
      end
    end

    def next_open_iteration(date)
      return unless date

      iterations.without_state_enum(:closed).where('start_date >= ?', date).order(start_date: :asc).first
    end

    def can_be_automated?
      active? && automatic? && duration_in_weeks.to_i > 0 && iterations_in_advance.to_i > 0
    end

    def can_roll_over?
      active? && automatic? && roll_over?
    end

    def duration_in_days
      duration_in_weeks * 7
    end

    def ensure_iterations_in_advance
      ::Iterations::Cadences::CreateIterationsWorker.perform_async(self.id) if self.can_be_automated?
    end

    def changed_iterations_automation_fields?
      (previous_changes.keys.map(&:to_sym) & ITERATIONS_AUTOMATION_FIELDS).present?
    end

    def update_iteration_sequences
      connection.execute <<~SQL
        UPDATE sprints SET sequence=t.row_number
        FROM (
          SELECT id, row_number() OVER (ORDER BY start_date) FROM sprints
          WHERE iterations_cadence_id = #{id}
        ) as t
        WHERE t.id=sprints.id AND (sprints.sequence IS DISTINCT FROM t.row_number)
      SQL
    end
  end
end
