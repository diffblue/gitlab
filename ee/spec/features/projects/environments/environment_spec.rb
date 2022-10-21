# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Environment detail page' do
  let_it_be(:project) { create(:project, :repository) }
  let(:environment) { create(:environment, name: 'production', project: project) }

  before do
    stub_licensed_features(protected_environments: true)
  end

  context 'when the environment is protected and the user has deployment-only access to it' do
    before do
      operator_group = create(:group)
      operator_user = create(:user)
      operator_group.add_reporter(operator_user)
      create(:project_group_link, :reporter, project: project, group: operator_group)
      create(:protected_environment, project: project, name: environment.name,
                                     authorize_group_to_deploy: operator_group)

      sign_in(operator_user)
    end

    context 'when environment can be re-deployed' do
      before do
        pipeline = create(:ci_pipeline, :success, project: project)
        build = create(:ci_build, :success, pipeline: pipeline, environment: environment.name)
        create(:deployment, :success, environment: environment, deployable: build, sha: project.commit.id)

        visit project_environment_path(project, environment)
      end

      it 'shows re-deploy button' do
        expect(page).to have_button(s_('Environments|Re-deploy to environment'))
      end
    end
  end
end
