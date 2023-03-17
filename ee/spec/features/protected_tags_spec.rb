# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Protected Tags', :js, feature_category: :source_code_management do
  include ProtectedTagHelpers

  let(:project) { create(:project, :repository) }
  let(:user) { project.first_owner }

  before do
    sign_in(user)
  end

  describe 'access control' do
    describe 'with ref permissions for users enabled' do
      before do
        stub_licensed_features(protected_refs_for_users: true)
      end

      include_examples 'protected tags > access control > EE'
    end

    describe 'with ref permissions for users disabled' do
      before do
        stub_licensed_features(protected_refs_for_users: false)
      end

      include_examples 'protected tags > access control > CE'

      describe 'with existing access levels' do
        let(:protected_tag) { create(:protected_tag, project: project) }

        it 'shows users that can push to the branch' do
          protected_tag.create_access_levels.new(user: create(:user, name: 'Jane'))
            .save!(validate: false)

          visit project_settings_repository_path(project)

          expect(page).to have_content("The following user can also create tags: "\
                                       "Jane")
        end

        it 'shows groups that can create to the branch' do
          protected_tag.create_access_levels.new(group: create(:group, name: 'Team Awesome'))
            .save!(validate: false)

          visit project_settings_repository_path(project)

          expect(page).to have_content("Members of this group can also create tags: "\
                                       "Team Awesome")
        end
      end
    end
  end

  context 'when the users for protected tags feature is on' do
    before do
      stub_licensed_features(protected_refs_for_users: true)
    end

    include_examples 'Deploy keys with protected tags' do
      let(:all_dropdown_sections) { ['Roles', 'Users', 'Deploy Keys'] }
    end
  end
end
