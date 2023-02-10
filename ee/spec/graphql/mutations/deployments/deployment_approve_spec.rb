# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Deployments::DeploymentApprove, feature_category: :environment_management do
  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:non_member) { create(:user) }
  let_it_be(:developer) { create(:user).tap { |u| project.add_developer(u) } }
  let_it_be(:maintainer) { create(:user).tap { |u| project.add_maintainer(u) } }

  let_it_be(:environment) { create(:environment, :staging, project: project) }
  let_it_be(:deployment) { create(:deployment, :blocked, user: developer, project: project, environment: environment) }
  let_it_be(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }
  let_it_be(:protected_environment_approval_rule) do
    create(:protected_environment_approval_rule, :maintainer_access, protected_environment: protected_environment)
  end

  before do
    stub_licensed_features(protected_environments: true)
  end

  describe '#resolve' do
    subject { mutation.resolve(id: deployment.to_global_id, status: ::Deployments::Approval.statuses.keys[0]) }

    context 'when deployment is not accessible to the user' do
      let(:user) { non_member }

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when deployment is accessible to the user' do
      let(:user) { developer }

      context 'when the user cannot approve or reject the deployment' do
        it 'returns a nil deployment approval and errors array' do
          expect(subject[:deployment_approval]).to be_nil
          expect(subject[:errors]).to contain_exactly(
            "You cannot approve your own deployment. " \
            "This configuration can be adjusted in the protected environment settings."
          )
        end
      end

      context 'when the user can approve or reject the deployment' do
        let(:user) { maintainer }

        it 'returns the deployment approval and an empty errors array' do
          expect(subject[:deployment_approval]).to eq(deployment.approvals.last)
          expect(subject[:errors]).to be_empty
        end
      end
    end
  end
end
