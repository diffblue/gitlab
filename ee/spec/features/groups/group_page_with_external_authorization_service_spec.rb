# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'The group page', feature_category: :subgroups do
  include ExternalAuthorizationServiceHelpers

  let(:user) { create(:user) }
  let(:group) { create(:group) }

  before do
    sign_in user
    group.add_owner(user)
  end

  describe 'The sidebar' do
    it 'shows the link to contribution analytics' do
      visit group_path(group)

      within('.nav-sidebar') do
        expect(page).to have_link('Contribution')
      end
    end

    context 'when epics are available' do
      before do
        stub_licensed_features(epics: true)
      end

      it 'shows the link to epics' do
        visit group_path(group)

        within('.nav-sidebar') do
          expect(page).to have_link('Epics')
        end
      end

      it 'hides the epics link when an external authorization service is enabled' do
        enable_external_authorization_service_check
        visit group_path(group)

        within('.nav-sidebar') do
          expect(page).not_to have_link('Epics')
        end
      end
    end
  end
end
