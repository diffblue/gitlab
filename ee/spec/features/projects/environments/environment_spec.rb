# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Environment detail page', feature_category: :environment_management do
  let_it_be(:project) do
    create(:project, :repository).tap { |p| p.ci_cd_settings.update!(forward_deployment_enabled: false) }
  end

  let_it_be(:environment) { create(:environment, name: 'production', project: project) }

  before do
    stub_licensed_features(protected_environments: true)
    stub_feature_flags(environment_details_vue: false)
  end

  context 'when the environment is protected and the user has deployment-only access to it' do
    let_it_be(:operator_group) { create(:group) }
    let_it_be(:operator_user) { create(:user).tap { |u| operator_group.add_reporter(u) } }

    before(:all) do
      create(:project_group_link, :reporter, project: project, group: operator_group)
      create(:protected_environment, project: project, name: environment.name,
                                     authorize_group_to_deploy: operator_group)

      create(:deployment, :success, environment: environment, sha: project.commit('HEAD~1').id).tap do |deployment|
        create(:ci_build, :manual, pipeline: deployment.deployable.pipeline, name: 'stop production',
                                   environment: environment.name)
      end
      create(:deployment, :success, environment: environment, sha: project.commit('HEAD~0').id).tap do |deployment|
        create(:ci_build, :manual, pipeline: deployment.deployable.pipeline, name: 'stop production',
                                   environment: environment.name)
      end
    end

    before do
      sign_in(operator_user)
      visit project_environment_path(project, environment)
    end

    it 'shows re-deploy button' do
      expect(page).to have_button(s_('Environments|Re-deploy to environment'))
    end

    it 'shows rollback button' do
      expect(page).to have_button(s_('Environments|Rollback environment'))
    end

    it 'shows play button with manual job' do
      expect(page).to have_button(s_('Environments|Deploy to...'), count: 2)
      expect(page).to have_link('stop production', count: 2)
    end
  end
end
