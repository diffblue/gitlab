# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StatusPage::PublishedIncident do
  let_it_be_with_reload(:issue) { create(:issue) }

  before do
    # prefill association cache
    issue&.status_page_published_incident
  end

  describe 'associations' do
    it { is_expected.to belong_to(:issue).inverse_of(:status_page_published_incident) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:issue) }
  end

  describe '.track' do
    subject { described_class.track(issue) }

    it { is_expected.to be_a(described_class) }
    it { is_expected.to eq(issue.status_page_published_incident) }
    specify { expect(subject.issue).to eq issue }
    specify { expect { subject }.to change { described_class.count }.by(1) }

    context 'when the incident already exists' do
      before do
        create(:status_page_published_incident, issue: issue)
      end

      it { is_expected.to be_a(described_class) }
      it { is_expected.to eq(issue.status_page_published_incident) }
      specify { expect(subject.issue).to eq issue }
      specify { expect { subject }.not_to change { described_class.count } }
    end

    context 'when issue is new record' do
      let(:issue) { build(:issue) }

      it { is_expected.to be_a(described_class) }
      it { is_expected.to eq(issue.status_page_published_incident) }
      specify { expect(subject.issue).to eq issue }
      specify { expect { subject }.to change { described_class.count }.by(1) }
    end

    context 'when issue is nil' do
      let(:issue) { nil }

      specify do
        expect { subject }
          .to raise_error(ActiveRecord::RecordInvalid, /Issue can't be blank/)
      end
    end
  end

  describe '.untrack' do
    subject { described_class.untrack(issue) }

    context 'when the incident is not yet tracked' do
      specify { expect { subject }.not_to change { described_class.count } }
    end

    context 'when the incident is already tracked' do
      before do
        create(:status_page_published_incident, issue: issue)
      end

      specify { expect { subject }.to change { described_class.count }.by(-1) }
    end
  end
end
