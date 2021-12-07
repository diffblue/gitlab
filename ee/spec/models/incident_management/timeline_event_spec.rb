# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::TimelineEvent do
  let_it_be(:project) { create(:project) }
  let_it_be(:timeline_event) { create(:incident_management_timeline_event, project: project) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:author) }
    it { is_expected.to belong_to(:incident) }
    it { is_expected.to belong_to(:updated_by_user) }
    it { is_expected.to belong_to(:promoted_from_note) }
  end

  describe 'validations' do
    subject { build(:incident_management_timeline_event) }

    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:incident) }
    it { is_expected.to validate_presence_of(:note) }
    it { is_expected.to validate_length_of(:note).is_at_most(10_000) }
    it { is_expected.to validate_presence_of(:note_html) }
    it { is_expected.to validate_length_of(:note_html).is_at_most(10_000) }
    it { is_expected.to validate_presence_of(:occurred_at) }
    it { is_expected.to validate_presence_of(:action) }
    it { is_expected.to validate_length_of(:action).is_at_most(128) }
  end

  describe '.order_occurred_at_asc' do
    let_it_be(:occurred_3mins_ago) { create(:incident_management_timeline_event, project: project, occurred_at: 3.minutes.ago) }
    let_it_be(:occurred_2mins_ago) { create(:incident_management_timeline_event, project: project, occurred_at: 2.minutes.ago) }

    subject(:order) { described_class.order_occurred_at_asc }

    it 'sorts timeline events by occurred_at' do
      is_expected.to eq([occurred_3mins_ago, occurred_2mins_ago, timeline_event])
    end
  end
end
