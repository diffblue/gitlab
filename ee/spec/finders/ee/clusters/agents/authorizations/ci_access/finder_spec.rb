# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::Authorizations::CiAccess::Finder, feature_category: :deployment_management do
  describe '#execute' do
    let_it_be(:top_level_group) { create(:group) }
    let_it_be(:agent_configuration_project) { create(:project, namespace: top_level_group) }

    let_it_be(:bottom_level_group) { create(:group, parent: top_level_group) }
    let_it_be(:requesting_project, reload: true) { create(:project, namespace: bottom_level_group) }

    let_it_be(:production_agent) { create(:cluster_agent, project: agent_configuration_project) }

    subject { described_class.new(requesting_project).execute }

    shared_examples_for 'licensed access_as' do
      context 'impersonate' do
        let(:config) { { access_as: { impersonate: {} } } }

        it { is_expected.to be_empty }

        context 'when available' do
          before do
            stub_licensed_features(cluster_agents_ci_impersonation: true)
          end

          it { is_expected.to match_array [authorization] }
        end
      end

      context 'ci_user' do
        let(:config) { { access_as: { ci_user: {} } } }

        it { is_expected.to be_empty }

        context 'when available' do
          before do
            stub_licensed_features(cluster_agents_ci_impersonation: true)
          end

          it { is_expected.to match_array [authorization] }
        end
      end

      context 'ci_job' do
        let(:config) { { access_as: { ci_job: {} } } }

        it { is_expected.to be_empty }

        context 'when available' do
          before do
            stub_licensed_features(cluster_agents_ci_impersonation: true)
          end

          it { is_expected.to match_array [authorization] }
        end
      end
    end

    describe 'project authorizations' do
      it_behaves_like 'licensed access_as' do
        let!(:authorization) do
          create(
            :agent_ci_access_project_authorization,
            agent: production_agent,
            project: requesting_project,
            config: config
          )
        end
      end
    end

    describe 'group authorizations' do
      it_behaves_like 'licensed access_as' do
        let!(:authorization) do
          create(
            :agent_ci_access_group_authorization,
            agent: production_agent,
            group: top_level_group,
            config: config
          )
        end
      end
    end
  end
end
