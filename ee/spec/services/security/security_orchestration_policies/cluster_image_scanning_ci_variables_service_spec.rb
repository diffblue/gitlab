# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::ClusterImageScanningCiVariablesService do
  describe '#execute' do
    let_it_be_with_refind(:project) { create(:project) }
    let(:service) { described_class.new(project: project) }

    let_it_be(:ci_variables) do
      { 'CLUSTER_IMAGE_SCANNING_DISABLED' => nil }
    end

    let(:requested_cluster) { 'production' }
    let(:action) do
      {
        clusters: {
          requested_cluster => {
            containers: %w[nginx falco],
            resources: %w[nginx-www nginx-admin],
            namespaces: %w[gitlab-production cluster-apps],
            kinds: %w[deployment daemonset]
          },
          staging: {
            containers: %w[falco],
            resources: %w[nginx-admin],
            namespaces: %w[cluster-apps],
            kinds: %w[daemonset]
          }
        }
      }
    end

    subject(:generated_variables) { service.execute(action) }

    shared_examples 'with cluster image scanning resource filters' do
      it 'generates comma-separated CI variable values for each resource filter' do
        ci_variables, _ = generated_variables

        expect(ci_variables).to eq(
          'CLUSTER_IMAGE_SCANNING_DISABLED' => nil,
          'CIS_CONTAINER_NAMES' => 'nginx,falco',
          'CIS_RESOURCE_NAMES' => 'nginx-www,nginx-admin',
          'CIS_RESOURCE_NAMESPACES' => 'gitlab-production,cluster-apps',
          'CIS_RESOURCE_KINDS' => 'deployment,daemonset'
        )
      end
    end

    shared_examples 'without variable attributes' do
      it 'does not generate variable attributes for pipeline' do
        _, variable_attributes = generated_variables

        expect(variable_attributes).to eq({})
      end
    end

    shared_examples 'for created cluster' do
      context 'when cluster with requested name does not exist' do
        let(:requested_cluster) { 'gilab-managed-apps' }

        it_behaves_like 'with cluster image scanning resource filters'
        it_behaves_like 'without variable attributes'
      end

      context 'when cluster with requested name exists' do
        it_behaves_like 'with cluster image scanning resource filters'

        it 'generates variable attributes for pipeline with CIS_KUBECONFIG variable' do
          _, variable_attributes = generated_variables

          expect(variable_attributes).to include(hash_including(key: 'CIS_KUBECONFIG', variable_type: :file))
        end
      end
    end

    context 'when cluster was not found' do
      it_behaves_like 'with cluster image scanning resource filters'
      it_behaves_like 'without variable attributes'
    end

    context 'when cluster was found for the group' do
      let_it_be_with_refind(:cluster) { create(:cluster, :group, :provided_by_user, name: 'production') }
      let_it_be_with_refind(:project) { create(:project, group: cluster.groups.first) }

      include_examples 'for created cluster'
    end

    context 'when cluster was found for the instance' do
      let_it_be_with_refind(:cluster) { create(:cluster, :instance, :provided_by_user, name: 'production') }
      let_it_be_with_refind(:project) { create(:project) }

      include_examples 'for created cluster'
    end

    context 'when cluster was found for the project' do
      let_it_be_with_refind(:cluster) { create(:cluster, :project, :provided_by_user, name: 'production') }
      let_it_be_with_refind(:project) { cluster.projects.first }

      include_examples 'for created cluster'
    end
  end
end
