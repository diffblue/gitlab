# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::EpicsController, feature_category: :portfolio_management do
  let(:group) { create(:group, :private) }
  let(:epic) { create(:epic, group: group) }
  let(:user) { create(:user) }

  describe 'GET #new' do
    before do
      stub_licensed_features(epics: true)
      sign_in(user)
      group.add_developer(user)
    end

    it_behaves_like "observability csp policy", described_class do
      let(:tested_path) do
        new_group_epic_path(group)
      end
    end
  end

  describe 'GET #show' do
    before do
      sign_in(user)
    end

    it_behaves_like "observability csp policy", described_class do
      before do
        group.add_developer(user)
        stub_licensed_features(epics: true)
      end

      let(:tested_path) do
        group_epic_path(group, epic)
      end
    end

    context 'for summarize notes feature' do
      let(:summarize_notes_enabled) { true }
      let(:group) { create(:group, :public) }

      before do
        stub_licensed_features(epics: true, summarize_notes: summarize_notes_enabled)
      end

      context 'when user is a member' do
        before do
          group.add_developer(user)
        end

        context 'when license is set' do
          it 'exposes the required feature flags' do
            get group_epic_path(group, epic)

            expect(response.body).to have_pushed_frontend_feature_flags(summarizeComments: true)
          end
        end

        context 'when license is not set' do
          let(:summarize_notes_enabled) { false }

          it 'does not expose the feature flags' do
            get group_epic_path(group, epic)

            expect(response.body).not_to have_pushed_frontend_feature_flags(summarizeComments: true)
          end
        end
      end

      context 'when user is not a member' do
        it 'does not expose the feature flags' do
          get group_epic_path(group, epic)

          expect(response.body).not_to have_pushed_frontend_feature_flags(summarizeComments: true)
        end
      end
    end
  end
end
