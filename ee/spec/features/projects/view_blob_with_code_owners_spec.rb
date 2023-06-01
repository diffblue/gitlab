# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'File blob > Code owners', :js, feature_category: :groups_and_projects do
  let(:project) { create(:project, :private, :repository) }
  let(:maintainer) { create(:user) }
  let(:code_owner) { create(:user, username: 'documentation-owner') }
  let(:developer) { create(:user) }

  before do
    sign_in(maintainer)
    project.add_member(maintainer, Gitlab::Access::MAINTAINER)
    project.add_developer(code_owner)
    project.add_member(developer, Gitlab::Access::DEVELOPER)
  end

  def visit_blob(path, anchor: nil, ref: 'master')
    visit project_blob_path(project, File.join(ref, path), anchor: anchor)

    wait_for_requests
  end

  context 'when there is a codeowners file' do
    context 'when the feature is available' do
      before do
        stub_licensed_features(code_owners: true)
      end

      it 'shows the code owners related to a file' do
        visit_blob('docs/CODEOWNERS', ref: 'with-codeowners')

        wait_for_requests
        within('.file-owner-content') do
          expect(page).to have_content _('Code owners')
          expect(page).to have_button('Show all')
          expect(page).to have_link _('Manage branch rules')
        end
      end

      it 'shows no codeowners text and link to docs when there are no code owners' do
        visit_blob('README.md')

        expect(page).to have_content _('Code owners')
        expect(page).to have_content _('Assign users and groups as approvers for specific file changes.')
        expect(page).to have_link _('Learn more.')
      end

      context 'when the user does not have maintainer access' do
        before do
          sign_in(developer)
        end

        it 'does not show link to branch rules' do
          visit_blob('docs/CODEOWNERS', ref: 'with-codeowners')
          wait_for_requests
          expect(page).to have_content _('Code owners')
          expect(page).not_to have_link _('Manage branch rules')
        end
      end
    end

    context 'when the feature is not available' do
      before do
        stub_licensed_features(code_owners: false)
      end

      it 'does not show the code owners related to a file' do
        visit_blob('docs/CODEOWNERS', ref: 'with-codeowners')

        expect(page).not_to have_content _('Code owners')
      end
    end
  end
end
