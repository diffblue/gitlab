# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Milestone do
  describe "Associations" do
    it { is_expected.to have_many(:boards) }
  end

  describe 'callbacks', feature_category: :global_search do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, namespace: group) }
    let_it_be_with_reload(:milestone) { create(:milestone, :with_dates, group: group) }
    let_it_be_with_reload(:another_milestone) { create(:milestone, :with_dates, group: group) }
    let_it_be(:epic) { create(:epic, group: group) }
    let_it_be(:another_epic) { create(:epic, group: group) }
    let_it_be(:issue) { create(:issue, project: project, milestone: milestone, epic: epic) }
    let_it_be(:another_issue) { create(:issue, project: project, milestone: another_milestone, epic: another_epic) }

    context 'when epic indexing is enabled' do
      before do
        allow(Epic).to receive(:elasticsearch_available?).and_return(true)
        stub_ee_application_setting(elasticsearch_indexing: true)
        Epics::UpdateDatesService.new([epic, another_epic]).execute
        epic.reload
        another_epic.reload
      end

      it 'updates epics inheriting from the milestone in Elasticsearch when the milestone start_date is updated' do
        expect(epic.start_date_sourcing_milestone).to eq(milestone)
        expect(another_epic.start_date_sourcing_milestone).to eq(another_milestone)

        expect(::Elastic::ProcessBookkeepingService).to receive(:track!).with(epic).once
        expect(::Elastic::ProcessBookkeepingService).not_to receive(:track!).with(another_epic)

        milestone.update!(start_date: milestone.start_date - 2.days)
        another_milestone.update!(title: "another milestone")
      end

      it 'updates epics inheriting from the milestone in Elasticsearch when the milestone due_date is updated' do
        expect(epic.due_date_sourcing_milestone).to eq(milestone)
        expect(another_epic.due_date_sourcing_milestone).to eq(another_milestone)

        expect(::Elastic::ProcessBookkeepingService).to receive(:track!).with(epic).once
        expect(::Elastic::ProcessBookkeepingService).not_to receive(:track!).with(another_epic)

        milestone.update!(due_date: milestone.due_date + 2.days)
        another_milestone.update!(title: "another milestone")
      end
    end
  end
end
