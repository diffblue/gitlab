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

  context 'includes' do
    context 'handling epics' do
      let(:epic) { create(:epic, group: group) }

      before do
        create(:epic_issue, issue: issue, epic: epic)
      end

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

        context 'when epic and issue are not from same group hierarchy' do
          let(:epic) { create(:epic) }

          specify 'epic ID' do
            expect(csv[0]['Epic ID']).to be_nil
            expect(csv[1]['Epic ID']).to be_nil
          end

          specify 'epic Title' do
            expect(csv[0]['Epic Title']).to be_nil
            expect(csv[1]['Epic Title']).to be_nil
          end
        end
      end
    end
  end
end
