# frozen_string_literal: true

module Dora
  # Denormalized storage for DevOps Research and Assessment (DORA) metric scores. Stored on monthly basis
  class PerformanceScore < ApplicationRecord
    self.table_name = 'dora_performance_scores'

    SCORES = { low: 10, medium: 20, high: 30 }.freeze

    belongs_to :project

    validates :project, presence: true
    validates :date, presence: true, uniqueness: { scope: :project_id }

    DailyMetrics::AVAILABLE_METRICS.each do |metric|
      enum metric.to_sym => SCORES, :_suffix => true
    end
  end
end
