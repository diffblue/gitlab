# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Getting Ci Cd Setting', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be_with_reload(:project) { create(:project, :repository) }
  let_it_be(:owner) { project.first_owner }
  let_it_be(:user) { create(:user) }

  let(:fields) do
    <<~QUERY
      #{all_graphql_fields_for('ProjectCiCdSetting', max_depth: 1)}
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('ciCdSettings', {}, fields)
    )
  end

  let(:settings_data) { graphql_data['project']['ciCdSettings'] }

  context 'without permissions' do
    before_all do
      project.add_reporter(user)
    end

    before do
      post_graphql(query, current_user: user)
    end

    it_behaves_like 'a working graphql query'

    specify { expect(settings_data).to be nil }
  end

  context 'with project permissions' do
    before do
      post_graphql(query, current_user: owner)
    end

    let(:skip_train_setting) { project.ci_cd_settings.merge_trains_skip_train_allowed? }

    it_behaves_like 'a working graphql query'

    it 'fetches the settings data' do
      expect(settings_data['mergeTrainsSkipTrainAllowed']).to eq skip_train_setting
    end
  end
end
