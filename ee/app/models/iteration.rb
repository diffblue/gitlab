# frozen_string_literal: true

class Iteration < ApplicationRecord
  include AtomicInternalId
  include Timebox
  include EachBatch
  include AfterCommitQueue
  include IidRoutes
  include FromUnion
  include UpdatedAtFilterable

  self.table_name = 'sprints'

  STATE_ENUM_MAP = {
    upcoming: 1,
    current: 2,
    closed: 3
  }.with_indifferent_access.freeze

  # For Iteration
  class Predefined
    None = ::Timebox::TimeboxStruct.new('None', 'none', ::Timebox::None.id, ::Iteration.name).freeze
    Any = ::Timebox::TimeboxStruct.new('Any', 'any', ::Timebox::Any.id, ::Iteration.name).freeze
    Current = ::Timebox::TimeboxStruct.new('Current', 'current', -4, ::Iteration.name).freeze

    ALL = [None, Any, Current].freeze

    def self.by_id(id)
      ::Iteration::Predefined::ALL.index_by(&:id)[id]
    end
  end

  attr_accessor :skip_future_date_validation

  belongs_to :group
  belongs_to :iterations_cadence, class_name: '::Iterations::Cadence', foreign_key: :iterations_cadence_id, inverse_of: :iterations

  has_many :issues, foreign_key: 'sprint_id'
  has_many :labels, -> { distinct.reorder('labels.title') }, through: :issues
  has_many :merge_requests, foreign_key: 'sprint_id'

  has_internal_id :iid, scope: :group

  validates :start_date, presence: true
  validates :due_date, presence: true
  validates :iterations_cadence, presence: true

  validate :dates_do_not_overlap, if: :start_or_due_dates_changed?
  validate :future_date, if: :start_or_due_dates_changed?, unless: :skip_future_date_validation
  validate :validate_group
  validate :uniqueness_of_title, if: :title_changed?

  before_save :set_iteration_state
  before_destroy :check_if_can_be_destroyed

  after_destroy :update_iteration_sequences, if: :iterations_cadence
  after_save :update_iteration_sequences, if: -> { iterations_cadence && saved_change_to_start_or_due_date? }
  after_commit :reset, on: [:update, :create], if: :saved_change_to_start_or_due_date?

  scope :of_groups, ->(ids) { where(group_id: ids) }

  scope :due_date_order_asc, -> { order(:due_date) }
  scope :due_date_order_desc, -> { order(due_date: :desc) }
  scope :sort_by_cadence_id_and_due_date_asc, -> { reorder(iterations_cadence_id: :asc).due_date_order_asc }
  scope :sort_by_cadence_id_and_due_date_desc, -> { reorder(iterations_cadence_id: :asc).due_date_order_desc }
  scope :sort_by_due_date_and_title, -> { reorder(:due_date).order(:title, { id: :asc }) }
  scope :upcoming, -> { with_state(:upcoming) }
  scope :current, -> { with_state(:current) }
  scope :closed, -> { with_state(:closed) }
  scope :opened, -> { with_states(:current, :upcoming) }
  scope :by_iteration_cadence_ids, ->(cadence_ids) { where(iterations_cadence_id: cadence_ids) }
  scope :with_start_date_after, ->(date) { where('start_date > :date', date: date) }

  scope :within_timeframe, -> (start_date, end_date) do
    where('sprints.start_date <= ?', end_date).where('sprints.due_date >= ?', start_date)
  end

  scope :start_date_passed, -> { where('start_date <= ?', Date.current).where('due_date >= ?', Date.current) }
  scope :due_date_passed, -> { where('due_date < ?', Date.current) }
  scope :with_cadence, -> { preload([iterations_cadence: :group]) }

  state_machine :state_enum, initial: :upcoming do
    event :start do
      transition upcoming: :current
    end

    event :close do
      transition [:upcoming, :current] => :closed
    end

    after_transition any => [:closed] do |iteration|
      iteration.run_after_commit do
        Iterations::RollOverIssuesWorker.perform_async([iteration.id]) if iteration.iterations_cadence&.can_roll_over?
      end
    end

    state :upcoming, value: Iteration::STATE_ENUM_MAP[:upcoming]
    state :current, value: Iteration::STATE_ENUM_MAP[:current]
    state :closed, value: Iteration::STATE_ENUM_MAP[:closed]
  end

  class << self
    alias_method :with_state, :with_state_enum
    alias_method :with_states, :with_state_enums

    def compute_state(start_date, due_date)
      today = Date.today

      if start_date > today
        :upcoming
      elsif due_date < today
        :closed
      else
        :current
      end
    end

    def reference_prefix
      '*iteration:'
    end

    def reference_pattern
      # NOTE: The id pattern only matches when all characters on the expression
      # are digits, so it will match *iteration:2 but not *iteration:2.1 because that's probably a
      # iteration name and we want it to be matched as such.
      @reference_pattern ||= %r{
      (#{::Project.reference_pattern})?
      #{::Regexp.escape(reference_prefix)}
      (?:
        (?<iteration_id>
          \d+(?!\S\w)\b # Integer-based iteration id, or
        ) |
        (?<iteration_name>
          [^"\s\<]+\b |  # String-based single-word iteration title, or
          "[^"]+"        # String-based multi-word iteration surrounded in quotes
        )
      )
    }x.freeze
    end

    def link_reference_pattern
      @link_reference_pattern ||= compose_link_reference_pattern('iterations', /(?<iteration>\d+)/)
    end

    def filter_by_state(iterations, state)
      case state
      when 'closed' then iterations.closed
      when 'current' then iterations.current
      when 'upcoming' then iterations.upcoming
      when 'opened' then iterations.opened
      when 'all' then iterations
      else raise ArgumentError, "Unknown state filter: #{state}"
      end
    end

    def search_title(query)
      fuzzy_search(query, [::Resolvers::IterationsResolver::DEFAULT_IN_FIELD], use_minimum_char_limit: contains_digits?(query))
    end

    def search_cadence_title(query)
      cadence_ids = Iterations::Cadence.search_title(query).pluck(:id)

      where(iterations_cadence_id: cadence_ids)
    end

    def search_title_or_cadence_title(query)
      union_sql = ::Gitlab::SQL::Union.new([search_title(query), search_cadence_title(query)]).to_sql

      ::Iteration.from("(#{union_sql}) #{table_name}")
    end

    private

    def contains_digits?(query)
      !(query =~ / \d+ /).nil?
    end
  end

  def period
    "#{start_date.to_s(:medium)} - #{due_date.to_s(:medium)}"
  end

  def display_text
    "#{iterations_cadence.title} #{period}"
  end

  def title=(value)
    if value.blank?
      write_attribute(:title, nil)
    else
      super
    end
  end

  def state
    STATE_ENUM_MAP.key(state_enum)
  end

  def state=(value)
    self.state_enum = STATE_ENUM_MAP[value]
  end

  def resource_parent
    group
  end

  # Show display_text when we manage to find an iteration, without the reference pattern,
  # since it's long and unsightly.
  def reference_link_text(from = nil)
    display_text
  end

  def supports_timebox_charts?
    resource_parent&.feature_available?(:iterations) && weight_available?
  end

  def set_iterations_cadence
    return if iterations_cadence
    # For now we support only group iterations
    # issue to clarify project iterations: https://gitlab.com/gitlab-org/gitlab/-/issues/299864
    return unless group

    # we need this as we use the cadence to validate the dates overlap for this iteration,
    # so in the case this runs before background migration we need to first set all iterations
    # in this group to a cadence before we can validate the dates overlap.
    default_cadence = find_or_create_default_cadence
    group.iterations.where(iterations_cadence_id: nil).update_all(iterations_cadence_id: default_cadence.id)

    self.iterations_cadence = default_cadence
  end

  def set_iteration_state
    self.state = self.class.compute_state(start_date, due_date)
  end

  ##
  # Returns the String necessary to reference a Timebox in Markdown. Group
  # timeboxes only support name references, and do not support cross-project
  # references.
  #
  # format - Symbol format to use (default: :iid, optional: :name)
  #
  # Examples:
  #
  #   Iteration.first.to_reference(format: :name)            # => "*iteration:\"goal\""
  #   Iteration.first.to_reference(same_namespace_project)   # => "gitlab-foss*iteration:1"
  #
  def to_reference(from = nil, format: :name, full: false)
    format_reference = timebox_format_reference(format)

    "#{self.class.reference_prefix}#{format_reference}"
  end

  def merge_requests_enabled?
    false
  end

  private

  def last_iteration_in_cadence?
    !::Iteration.by_iteration_cadence_ids(iterations_cadence_id).with_start_date_after(due_date).exists?
  end

  def check_if_can_be_destroyed
    return if closed?

    unless last_iteration_in_cadence?
      errors.add(:base, "upcoming/current iterations can't be deleted unless they are the last one in the cadence")
      throw :abort # rubocop: disable Cop/BanCatchThrow
    end
  end

  def timebox_format_reference(format = :id)
    raise ::ArgumentError, _('Unknown format') unless [:id, :name].include?(format)

    if format == :name && title.present?
      %("#{title}")
    else
      id
    end
  end

  def start_or_due_dates_changed?
    start_date_changed? || due_date_changed?
  end

  def saved_change_to_start_or_due_date?
    saved_change_to_start_date? || saved_change_to_due_date?
  end

  # ensure dates do not overlap with other Iterations in the same cadence tree
  def dates_do_not_overlap
    return unless iterations_cadence
    return unless iterations_cadence.iterations.where.not(id: self.id).within_timeframe(start_date, due_date).exists?

    errors.add(:base, s_("Iteration|Dates cannot overlap with other existing Iterations within this iterations cadence"))
  end

  def future_date
    if start_or_due_dates_changed?
      errors.add(:start_date, s_("Iteration|cannot be more than 500 years in the future")) if start_date > 500.years.from_now
      errors.add(:due_date, s_("Iteration|cannot be more than 500 years in the future")) if due_date > 500.years.from_now
    end
  end

  def update_iteration_sequences
    iterations_cadence.update_iteration_sequences
  end

  def find_or_create_default_cadence
    default_cadence = ::Iterations::Cadence.order(id: :asc).find_by(group: group, automatic: false)
    return default_cadence if default_cadence

    cadence_title = "#{group.name} Iterations"
    start_date = self.start_date || Date.today

    ::Iterations::Cadence.new(
      group: group,
      title: cadence_title,
      start_date: start_date,
      automatic: false,
      iterations_in_advance: 2,
      duration_in_weeks: 2
    ).tap { |new_cadence| new_cadence.save!(validate: false) }
  end

  # TODO: remove this as part of https://gitlab.com/gitlab-org/gitlab/-/issues/296100
  def validate_group
    return if iterations_cadence&.group_id == group_id
    return unless iterations_cadence

    errors.add(:group, s_('is not valid. The iteration group has to match the iteration cadence group.'))
  end

  # TODO: remove this as part of https://gitlab.com/gitlab-org/gitlab/-/issues/354878
  def uniqueness_of_title
    relation = self.class.where(iterations_cadence_id: self.iterations_cadence)
    title_exists = relation.find_by_title(title)

    errors.add(:title, _('already being used for another iteration within this cadence.')) if title_exists
  end
end
