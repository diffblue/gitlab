# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['BoardEpic'] do
  it { expect(described_class.graphql_name).to eq('BoardEpic') }

  it 'has specific fields' do
    expect(described_class).to have_graphql_field(:user_preferences)
  end

  describe '#user_preferences' do
    let_it_be(:user) { create(:user) }
    let(:epics) { result['data']['group']['board']['epics']['nodes'] }
    let(:epic_preferences) { epics.first['userPreferences'] }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:board) { create(:board, group: group) }
    let_it_be(:epic) { create(:epic, group: group) }
    let_it_be(:epic_issue) { create(:epic_issue, epic: epic, issue: issue) }

    let(:query) do
      %(
        {
          group(fullPath: "#{group.full_path}") {
            board(id: "#{board.to_global_id}") {
              epics {
                nodes {
                  id
                  userPreferences {
                    collapsed
                  }
                }
              }
            }
          }
        }
      )
    end

    subject(:result) { GitlabSchema.execute(query, context: context).as_json }

    before do
      stub_licensed_features(epics: true)
      group.add_developer(user)
    end

    context 'when user is not set' do
      let(:context) { { board: board } }

      it 'does not return any epics' do
        expect(epics).to be_empty
      end
    end

    context 'when user and board is set' do
      let(:context) { { board: board, current_user: user } }

      it 'returns nil if there are not preferences' do
        expect(epics).not_to be_empty
        expect(epic_preferences).to be_nil
      end

      context 'when user preferences are set' do
        let_it_be(:epic_user_preference) { create(:epic_user_preference, board: board, epic: epic, user: user) }

        it 'returns user preferences' do
          expect(epics).not_to be_empty
          expect(epic_preferences['collapsed']).to eq(false)
        end
      end
    end
  end
end
