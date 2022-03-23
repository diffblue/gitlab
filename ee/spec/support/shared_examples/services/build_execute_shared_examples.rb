# frozen_string_literal: true

RSpec.shared_examples 'restricts access to protected environments' do |developer_access_when_protected, developer_access_when_unprotected|
  context 'when build is related to a protected environment' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :repository) }
    let(:pipeline) { create(:ci_pipeline, project: project) }
    let(:environment) { create(:environment, project: project, name: 'production') }
    let(:build) { create(:ci_build, :success, pipeline: pipeline, environment: environment.name, project: project) }
    let(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }
    let(:service) { described_class.new(project, user) }

    before do
      stub_licensed_features(protected_environments: true)

      project.add_developer(user)
      protected_environment
    end

    context 'when user does not have access to the environment' do
      it 'raises Gitlab::Access::DeniedError' do
        expect { subject }.to raise_error Gitlab::Access::AccessDeniedError
      end
    end

    context 'when user has access to the environment' do
      before do
        protected_environment.deploy_access_levels.create!(user: user)
      end

      it 'enqueues the build' do
        is_expected.to be_pending
      end
    end
  end
end
