# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::ExportCsvService do
  let_it_be(:user) { create(:user) }

  let(:group) { create(:group) }
  let(:project) { create(:project, :public, group: group) }
  let!(:issue) { create(:issue, project: project, author: user) }
  let!(:issue2) { create(:issue, project: project, author: user) }
  let(:subject) { described_class.new(Issue.all, project) }

  def csv
    CSV.parse(subject.csv_data, headers: true)
  end

  shared_examples 'including issues with epics' do
    context 'with epics disabled' do
      it 'does not include epics information' do
        expect(csv[0]).not_to have_key('Epic ID')
      end
    end

    context 'with epics enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      specify 'epic ID' do
        expect(csv[0]['Epic ID']).to eq(epic.id.to_s)
        expect(csv[1]['Epic ID']).to be_nil
      end

      specify 'epic Title' do
        expect(csv[0]['Epic Title']).to eq(epic.title)
        expect(csv[1]['Epic Title']).to be_nil
      end
    end
  end

  context 'includes' do
    context 'when epic and issue are from the same group' do
      let(:epic) { create(:epic, group: group) }

      before do
        create(:epic_issue, issue: issue, epic: epic)
      end

      it_behaves_like 'including issues with epics'
    end

    context 'when epic is in an ancestor group' do
      let_it_be(:ancestor) { create(:group) }
      let_it_be(:epic) { create(:epic, group: ancestor) }

      before do
        group.update!(parent: ancestor)
        create(:epic_issue, issue: issue, epic: epic)
      end

      it_behaves_like 'including issues with epics'
    end
  end

  context 'when epic issue is not valid' do
    let(:epic) { create(:epic, group: group) }

    before do
      create(:epic_issue, issue: issue, epic: epic)

      allow_next_instance_of(EpicIssue) do |epic_issue|
        allow(epic_issue).to receive(:valid?).and_return(false)
      end
    end

    it 'does not include epics information' do
      expect(csv[0]).not_to have_key('Epic ID')
    end
  end
end
