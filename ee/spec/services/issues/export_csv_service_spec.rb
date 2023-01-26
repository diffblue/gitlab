# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::ExportCsvService, feature_category: :importers do
  let_it_be(:user) { create(:user) }

  let(:group) { create(:group) }
  let(:project) { create(:project, :public, group: group) }
  let!(:issue) { create(:issue, project: project, author: user) }
  let!(:issue2) { create(:issue, project: project, author: user) }
  let(:subject) { described_class.new(Issue.all, project, user) }

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

  context 'with epic' do
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

    context 'when some epics are not readable by user' do
      let(:unauthorized_epic) { create(:epic, group: create(:group, :private)) }
      let(:epic) { create(:epic, group: group) }

      before do
        stub_licensed_features(epics: true)
        create(:epic_issue, issue: issue, epic: unauthorized_epic)
        create(:epic_issue, issue: issue2, epic: epic)
      end

      it 'redacts epic title' do
        expect(csv[0]['Epic ID']).to eq(unauthorized_epic.id.to_s)
        expect(csv[0]['Epic Title']).to eq(nil)
        expect(csv[1]['Epic ID']).to eq(epic.id.to_s)
        expect(csv[1]['Epic Title']).to eq(epic.title)
      end
    end
  end
end
