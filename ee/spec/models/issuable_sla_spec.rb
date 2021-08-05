# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuableSla do
  describe 'associations' do
    it { is_expected.to belong_to(:issue).required }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:due_at) }
  end

  describe 'scopes' do
    let_it_be(:project) { create(:project) }
    let_it_be_with_reload(:issue) { create(:issue, project: project) }
    let_it_be(:issuable_closed_sla) { create(:issuable_sla, :issuable_closed, issue: create(:issue, project: project)) }
    let_it_be(:future_due_at_sla) { create(:issuable_sla, issue: create(:issue, project: project), due_at: 1.hour.from_now) }

    describe '.exceeded' do
      subject { described_class.exceeded }

      let!(:issuable_sla) { create(:issuable_sla, issue: issue, due_at: 1.hour.ago) }

      it { is_expected.to contain_exactly(issuable_sla) }

      context 'marked as issuable closed' do
        let!(:issuable_sla) { create(:issuable_sla, :issuable_closed, issue: issue, due_at: 1.hour.ago) }

        it { is_expected.to be_empty }
      end

      context 'due_at has not passed' do
        before do
          issuable_sla.update!(due_at: 1.hour.from_now)
        end

        it { is_expected.to be_empty }
      end

      context 'label applied' do
        let!(:issuable_sla) { create(:issuable_sla, :label_applied, issue: issue, due_at: 1.hour.ago) }

        it { is_expected.to be_empty }
      end
    end
  end
end
