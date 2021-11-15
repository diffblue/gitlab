# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::TimelineEvent do
  let_it_be(:timeline_event) { create(:incident_management_timeline_event) }

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
end
