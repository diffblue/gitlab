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
      let(:group) { create(:group, :public) }

      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(user, :summarize_notes, epic).and_return(summarize_notes_enabled)

        stub_licensed_features(epics: true)
      end

      context 'when feature is available set' do
        let(:summarize_notes_enabled) { true }

        it 'exposes the required feature flags' do
          get group_epic_path(group, epic)

          expect(response.body).to have_pushed_frontend_feature_flags(summarizeComments: true)
        end
      end

      context 'when feature is not available' do
        let(:summarize_notes_enabled) { false }

        it 'does not expose the feature flags' do
          get group_epic_path(group, epic)

          expect(response.body).not_to have_pushed_frontend_feature_flags(summarizeComments: true)
        end
      end
    end
  end
end
