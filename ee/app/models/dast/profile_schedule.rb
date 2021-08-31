# frozen_string_literal: true

class Dast::ProfileSchedule < ApplicationRecord
  include CronSchedulable

  CRON_DEFAULT = '* * * * *'

  self.table_name = 'dast_profile_schedules'

  belongs_to :project
  belongs_to :dast_profile, class_name: 'Dast::Profile', optional: false, inverse_of: :dast_profile_schedule
  belongs_to :owner, class_name: 'User', optional: true, foreign_key: :user_id

  validates :timezone, presence: true, inclusion: { in: :timezones }
  validates :starts_at, presence: true
  validates :cadence, json_schema: { filename: 'dast_profile_schedule_cadence', draft: 7 }
  validates :dast_profile_id, uniqueness: true

  serialize :cadence, Serializers::Json # rubocop:disable Cop/ActiveRecordSerialize

  scope :with_project, -> { includes(:project) }
  scope :with_profile, -> { includes(dast_profile: [:dast_site_profile, :dast_scanner_profile]) }
  scope :with_owner, -> { includes(:owner) }
  scope :active, -> { where(active: true) }

  before_save :set_cron, :set_next_run_at

  def repeat?
    cadence.present?
  end

  def schedule_next_run!
    return deactivate! unless repeat?

    super
  end

  def audit_details
    owner&.name
  end

  private

  def deactivate!
    update!(active: false)
  end

  def cron_timezone
    Time.zone.name
  end

  def set_cron
    self.cron =
      if repeat?
        Gitlab::Ci::CronParser.parse_natural_with_timestamp(starts_at, cadence)
      else
        CRON_DEFAULT
      end
  end

  def set_next_run_at
    return super unless will_save_change_to_starts_at?

    self.next_run_at = cron_worker_next_run_from(starts_at)
  end

  def worker_cron_expression
    Settings.cron_jobs['app_sec_dast_profile_schedule_worker']['cron']
  end

  def timezones
    @timezones ||= ActiveSupport::TimeZone.all.map { |tz| tz.tzinfo.identifier }
  end
end
