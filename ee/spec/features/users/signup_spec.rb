# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Signup', feature_category: :system_access do
  context 'almost there page' do
    context 'when public visibility is restricted' do
      before do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
      end

      it 'hides Explore link' do
        visit users_almost_there_path

        expect(page).to have_no_link("Explore")
      end

      it 'hides help link' do
        visit users_almost_there_path

        expect(page).to have_no_link("Help")
      end
    end
  end
end
