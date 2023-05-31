# frozen_string_literal: true

module Dora
  # Denormalized storage for DevOps Research and Assessment (DORA) metric scores. Stored on monthly basis
  class PerformanceScore < ApplicationRecord
    self.table_name = 'dora_performance_scores'

    SCORES = { low: 10, medium: 20, high: 30 }.freeze

    belongs_to :project

    validates :project, presence: true
    validates :date, presence: true, uniqueness: { scope: :project_id }

    scope :for_projects, ->(projects) do
      where(project: projects)
    end

    scope :for_dates, ->(date_or_range) do
      where(date: date_or_range)
    end

    scope :group_counts_by_metric, ->(metric_symbol) do
      group(metric_symbol).count
    end

    DailyMetrics::AVAILABLE_METRICS.each do |metric|
      enum metric.to_sym => SCORES, :_suffix => true
    end

    def self.refresh!(project, date)
      date = date.beginning_of_month.to_date
      scores = Analytics::DoraPerformanceScoreCalculator.scores_for(project, date)
      score_data = scores.merge(project_id: project.id, date: date)

      upsert(score_data, unique_by: [:project_id, :date])
    end
  end
end
