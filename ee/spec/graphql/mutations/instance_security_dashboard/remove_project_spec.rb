# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::InstanceSecurityDashboard::RemoveProject do
  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }

  describe '#resolve' do
    let_it_be(:project) { create(:project) }
    let_it_be(:already_added_project) { create(:project) }

    let_it_be(:user) { create(:user, security_dashboard_projects: [already_added_project]) }

    let(:project_id) { GitlabSchema.id_from_object(project) }

    before_all do
      already_added_project.add_developer(user)
    end

    subject { mutation.resolve(id: project_id) }

    context 'when user is not logged_in' do
      let(:current_user) { nil }

      it 'raises Gitlab::Graphql::Errors::ResourceNotAvailable error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when user is logged_in' do
      let(:current_user) { user }

      context 'when security_dashboard is not enabled' do
        it 'raises Gitlab::Graphql::Errors::ResourceNotAvailable error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when security_dashboard is enabled' do
        before do
          stub_licensed_features(security_dashboard: true)
        end

        context 'when project is not configured in security dashboard' do
          it { is_expected.to eq(errors: ['The project does not belong to your dashboard or you don\'t have permission to perform this action']) }
        end

        context 'when project is configured in security dashboard' do
          let(:project_id) { GitlabSchema.id_from_object(already_added_project) }

          it { is_expected.to eq(errors: []) }
        end
      end
    end
  end
end
