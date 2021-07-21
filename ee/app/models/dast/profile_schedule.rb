# frozen_string_literal: true

class Dast::ProfileSchedule < ApplicationRecord
  include CronSchedulable

  self.table_name = 'dast_profile_schedules'

  belongs_to :project
  belongs_to :dast_profile, class_name: 'Dast::Profile', optional: false, inverse_of: :dast_profile_schedules
  belongs_to :owner, class_name: 'User', optional: true, foreign_key: :user_id

  validates :cron, presence: true
  validates :next_run_at, presence: true

  scope :with_project, -> { includes(:project) }
  scope :with_profile, -> { includes(dast_profile: [:dast_site_profile, :dast_scanner_profile]) }
  scope :with_owner, -> { includes(:owner) }
  scope :active, -> { where(active: true) }

  private

  def cron_timezone
    next_run_at.zone
  end

  def worker_cron_expression
    Settings.cron_jobs['app_sec_dast_profile_schedule_worker']['cron']
  end
end
