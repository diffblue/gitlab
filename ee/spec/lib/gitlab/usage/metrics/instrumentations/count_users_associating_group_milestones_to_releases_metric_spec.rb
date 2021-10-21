# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountUsersAssociatingGroupMilestonesToReleasesMetric do
  before do
    stub_licensed_features(group_milestone_project_releases: true)
  end

  let(:group_milestone) { create(:milestone, :on_group) }
  let(:project) { create(:project, group: group_milestone.group) }
  let!(:release) { create(:release, created_at: 3.days.ago) }
  let!(:release_with_milestone) { create(:release, :with_milestones, created_at: 3.days.ago) }
  let!(:release_with_group_milestone) { create(:release, created_at: 3.days.ago, project: project, milestones: [group_milestone]) }

  it_behaves_like 'a correct instrumented metric value', { time_frame: '28d', data_source: 'database' } do
    let(:expected_value) { 1 }
  end
end
