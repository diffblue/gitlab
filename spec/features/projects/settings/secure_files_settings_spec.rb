# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Secure Files Settings' do
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:anonymous) { create(:user) }
  let_it_be(:unconfirmed) { create(:user, :unconfirmed) }
  let_it_be(:project) { create(:project, creator_id: maintainer.id) }

  before_all do
    project.add_maintainer(maintainer)
    project.add_developer(developer)
    project.add_guest(guest)
  end

  let(:item_id) { :secure_files }

  context 'when the :ci_secure_files feature flag is enabled' do
    before do
      stub_feature_flags(ci_secure_files: true)
      stub_feature_flags(ci_secure_files_read_only: false)

      sign_in(user)
      visit project_settings_ci_cd_path(project)
    end

    context 'authenticated user with admin permissions' do
      let(:user) { maintainer }

      it 'shows the secure files settings' do
        expect(page).to have_content('Secure Files')
      end
    end

    context 'authenticated user with read permissions' do
      let(:user) { developer }

      it 'shows the secure files settings' do
        expect(page).not_to have_content('Secure Files')
      end
    end

    context 'authenticated user with guest permissions' do
      let(:user) { guest }

      it 'does not show the secure files settings' do
        expect(page).not_to have_content('Secure Files')
      end
    end

    context 'authenticated user with no permissions' do
      let(:user) { anonymous }

      it 'does not show the secure files settings' do
        expect(page).not_to have_content('Secure Files')
      end
    end

    context 'unconfirmed user' do
      let(:user) { unconfirmed }

      it 'does not show the secure files settings' do
        expect(page).not_to have_content('Secure Files')
      end
    end
  end

  context 'when the :ci_secure_files feature flag is enabled' do
    before do
      stub_feature_flags(ci_secure_files: false)
      stub_feature_flags(ci_secure_files_read_only: false)

      sign_in(user)
      visit project_settings_ci_cd_path(project)
    end

    context 'authenticated user with admin permissions' do
      let(:user) { maintainer }

      it 'shows the secure files settings' do
        expect(page).not_to have_content('Secure Files')
      end
    end
  end
end
