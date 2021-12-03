# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserPreference do
  let(:user_preference) { create(:user_preference) }

  shared_examples 'updates roadmap_epics_state' do |state|
    it 'saves roadmap_epics_state in user_preference' do
      user_preference.update!(roadmap_epics_state: state)

      expect(user_preference.reload.roadmap_epics_state).to eq(state)
    end
  end

  describe 'roadmap_epics_state' do
    context 'when set to open epics' do
      it_behaves_like 'updates roadmap_epics_state', Epic.state_ids[:opened]
    end

    context 'when set to closed epics' do
      it_behaves_like 'updates roadmap_epics_state', Epic.state_ids[:closed]
    end

    context 'when reset to all epics' do
      it_behaves_like 'updates roadmap_epics_state', nil
    end
  end
end
