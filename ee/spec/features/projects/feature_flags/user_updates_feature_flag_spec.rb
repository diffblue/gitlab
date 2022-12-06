# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User updates feature flag', :js, feature_category: :feature_flags do
  include FeatureFlagHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: user.namespace) }

  let_it_be(:feature_flag) do
    create_flag(project, 'test_flag', false,
                version: Operations::FeatureFlag.versions['new_version_flag'],
                description: 'For testing')
  end

  let_it_be(:strategy) do
    create(:operations_strategy, feature_flag: feature_flag, name: 'default', parameters: {})
  end

  let_it_be(:scope) do
    create(:operations_scope, strategy: strategy, environment_scope: '*')
  end

  before_all do
    project.add_developer(user)
  end

  before do
    stub_licensed_features(feature_flags_code_references: premium)
    sign_in(user)
  end

  context 'with a premium license' do
    let(:premium) { true }

    it 'links to a search page for code references' do
      visit(edit_project_feature_flag_path(project, feature_flag))

      click_button _('More actions')
      expect(page).to have_link s_('FeatureFlags|Search code references'), href: search_path(project_id: project.id, search: feature_flag.name, scope: :blobs)
    end
  end

  context 'without a premium license' do
    let(:premium) { false }

    it 'does not link to a search page for code references' do
      visit(edit_project_feature_flag_path(project, feature_flag))

      expect(page).not_to have_button _('More actions')
      expect(page).not_to have_link s_('FeatureFlags|Search code references'), href: search_path(project_id: project.id, search: feature_flag.name, scope: :blobs)
    end
  end
end
