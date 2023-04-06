# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DeploymentPolicy, feature_category: :continuous_delivery do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:maintainer) { create(:user).tap { |u| project.add_maintainer(u) } }
  let_it_be(:developer) { create(:user).tap { |u| project.add_developer(u) } }
  let_it_be(:reporter) { create(:user).tap { |u| project.add_reporter(u) } }
  let_it_be(:operator_group) { create(:group) }

  let(:user) { maintainer }

  let(:environment) { create(:environment, project: project) }
  let(:deployment) { create(:deployment, environment: environment, project: project) }

  subject { described_class.new(user, deployment) }

  before_all do
    operator_group.add_developer(reporter)
  end

  before do
    stub_licensed_features(protected_environments: true)
  end

  context 'when the user is allowed to deploy' do
    let!(:protected_environment) do
      create(:protected_environment, name: environment.name, project: project, authorize_user_to_deploy: user)
    end

    it { expect_allowed(:destroy_deployment) }

    context 'when user is developer' do
      let(:user) { developer }

      it { expect_disallowed(:destroy_deployment) }
    end
  end

  context 'when maintainers are allowed to deploy and approve' do
    let!(:protected_environment) do
      create(
        :protected_environment,
        :maintainers_can_deploy,
        name: environment.name,
        project: project,
        required_approval_count: 1
      )
    end

    it { expect_allowed(:approve_deployment) }

    context 'when user is developer' do
      let(:user) { developer }

      it { expect_disallowed(:approve_deployment) }
    end
  end

  context 'when specific group is allowed to approve' do
    let!(:protected_environment) do
      create(:protected_environment, :maintainers_can_deploy, name: environment.name, project: project)
    end

    let!(:approval_rule) do
      create(:protected_environment_approval_rule, group: operator_group, protected_environment: protected_environment)
    end

    let(:user) { reporter }

    it { expect_allowed(:approve_deployment) }

    context 'when user is developer' do
      let(:user) { developer }

      it { expect_disallowed(:approve_deployment) }
    end
  end

  context 'when the user is not allowed to deploy' do
    let!(:protected_environment) do
      create(:protected_environment, name: environment.name, project: project, authorize_user_to_deploy: create(:user))
    end

    it { expect_disallowed(:destroy_deployment) }
  end
end
