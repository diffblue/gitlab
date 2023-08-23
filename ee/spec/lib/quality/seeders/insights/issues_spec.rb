# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Quality::Seeders::Insights::Issues, feature_category: :quality_management do
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, group: group) }

  describe '#seed' do
    # Runs the seed only once
    before_all do
      described_class.new(project: project).seed(backfill_weeks: 2, average_issues_per_week: 2)
    end

    it 'creates issues with iteration and weight' do
      # The seed creates a random number of issues,
      # so we test if all of them has values present.
      iteration_ids = project.issues.pluck(:sprint_id).compact
      weights = project.issues.pluck(:weight).compact
      issues_count = project.issues.count

      expect(iteration_ids.size).to eq(issues_count)
      expect(weights.size).to eq(issues_count)
    end

    it 'generates DORA metrics' do
      dora_metrics = project.environments.last.dora_daily_metrics

      expect(dora_metrics).not_to be_empty
    end
  end
end
