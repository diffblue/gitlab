# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Vulnerabilities::ContainerImagesResolver, feature_category: :vulnerability_management do
  include GraphqlHelpers

  describe '#resolve' do
    subject { resolve(described_class, obj: vulnerable, args: {}, ctx: { current_user: current_user }) }

    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, namespace: group) }
    let_it_be(:user) { create(:user, security_dashboard_projects: [project]) }

    let_it_be(:vulnerability) { create(:vulnerability, project: project, report_type: :cluster_image_scanning) }
    let_it_be(:finding) do
      create(:vulnerabilities_finding, :with_cluster_image_scanning_scanning_metadata,
             project: project, vulnerability: vulnerability)
    end

    let(:current_user) { user }

    shared_examples 'fetches vulnerability container images' do
      context 'when user is not logged in' do
        let(:current_user) { nil }

        it { is_expected.to be_blank }
      end

      context 'when user is logged in' do
        let(:current_user) { user }

        context 'when user does not have permissions' do
          it { is_expected.to be_blank }
        end

        context 'when user have permissions to access vulnerabilities' do
          before do
            stub_licensed_features(security_dashboard: true)
            project.add_developer(current_user)
            group.add_developer(current_user)
          end

          it 'returns related container images' do
            expect(subject.map(&:location_image)).to include('alpine:3.7')
          end
        end
      end
    end

    context 'when resolved for project' do
      let(:vulnerable) { project }

      it_behaves_like 'fetches vulnerability container images'
    end
  end
end
