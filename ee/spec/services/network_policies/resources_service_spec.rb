# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NetworkPolicies::ResourcesService do
  let(:service) { NetworkPolicies::ResourcesService.new(environment_id: environment_id, project: project) }
  let(:environment) { create(:environment, project: project) }
  let(:environment_id) { environment.id }
  let(:project) { create(:project) }
  let(:cluster) { create(:cluster, :instance) }
  let!(:cluster_kubernetes_namespace) { create(:cluster_kubernetes_namespace, project: project, cluster: cluster, environment: environment, namespace: 'namespace') }
  let(:platform) { double('Clusters::Platforms::Kubernetes', kubeclient: kubeclient, cluster_id: cluster.id) }
  let(:kubeclient) { double('Kubeclient::Client') }
  let(:policy) do
    Gitlab::Kubernetes::NetworkPolicy.new(
      name: 'policy',
      namespace: 'another',
      selector: { matchLabels: { role: 'db' } },
      ingress: [{ from: [{ namespaceSelector: { matchLabels: { project: 'myproject' } } }] }],
      environment_ids: [environment.id]
    )
  end

  let(:cilium_policy) do
    Gitlab::Kubernetes::CiliumNetworkPolicy.new(
      name: 'cilium_policy',
      namespace: 'another',
      resource_version: '102',
      selector: { matchLabels: { role: 'db' } },
      ingress: [{ endpointFrom: [{ matchLabels: { project: 'myproject' } }] }],
      environment_ids: [environment.id]
    )
  end

  before do
    allow_any_instance_of(Clusters::KubernetesNamespace).to receive(:platform_kubernetes).and_return(platform)
  end

  describe '#execute' do
    subject { service.execute }

    it 'returns success response with policies from the deployment namespace' do
      expect(kubeclient).to receive(:get_network_policies).with(namespace: cluster_kubernetes_namespace.namespace) { [policy.generate] }
      expect(kubeclient).to receive(:get_cilium_network_policies).with(namespace: cluster_kubernetes_namespace.namespace) { [cilium_policy.generate] }
      expect(subject).to be_success
      expect(subject.payload.count).to eq(2)
      expect(subject.payload.first.as_json).to eq(policy.as_json)
      expect(subject.payload.last.as_json).to eq(cilium_policy.as_json)
    end

    it_behaves_like 'tracking unique hll events' do
      subject(:request) { service.execute }

      let(:target_event) { 'clusters_using_network_policies_ui' }
      let(:expected_value) { instance_of(Integer) }

      before do
        allow(kubeclient).to receive(:get_network_policies)
          .with(namespace: cluster_kubernetes_namespace.namespace)
          .and_return [policy.generate]

        allow(kubeclient).to receive(:get_cilium_network_policies)
          .with(namespace: cluster_kubernetes_namespace.namespace)
          .and_return [cilium_policy.generate]
      end
    end

    context 'without deployment_platform' do
      let(:platform) { nil }

      it 'returns error response' do
        expect(subject).to be_error
        expect(subject.http_status).to eq(:bad_request)
        expect(subject.message).not_to be_nil
      end
    end

    context 'with Kubeclient::HttpError related to network policies' do
      before do
        allow(kubeclient).to receive(:get_network_policies).and_raise(Kubeclient::HttpError.new(500, 'system failure', nil))
      end

      it 'returns error response' do
        expect(subject).to be_error
        expect(subject.http_status).to eq(:bad_request)
        expect(subject.message).not_to be_nil
        expect(subject.payload).to be_empty
      end
    end

    context 'with Kubeclient::HttpError related to cilium network policies' do
      before do
        allow(kubeclient).to receive(:get_network_policies) { [policy.generate] }
        allow(kubeclient).to receive(:get_cilium_network_policies).and_raise(Kubeclient::HttpError.new(400, 'not found', nil))
      end

      it 'returns error response' do
        expect(subject).to be_error
        expect(subject.http_status).to eq(:bad_request)
        expect(subject.message).not_to be_nil
        expect(subject.payload.first.as_json).to eq(policy.as_json)
      end
    end

    context 'without environment_id' do
      let(:environment_id) { nil }
      let(:cluster_2) { create(:cluster, :project) }
      let!(:cluster_kubernetes_namespace_2) { create(:cluster_kubernetes_namespace, project: project, cluster: cluster_2, environment: environment, namespace: 'namespace_2') }
      let(:policy_2) do
        Gitlab::Kubernetes::NetworkPolicy.new(
          name: 'policy_2',
          namespace: 'another_2',
          selector: { matchLabels: { role: 'db' } },
          ingress: [{ from: [{ namespaceSelector: { matchLabels: { project: 'myproject' } } }] }],
          environment_ids: [environment.id]
        )
      end

      it 'returns success response with policies from two deployment namespaces', :aggregate_failures do
        expect(kubeclient).to receive(:get_network_policies).with(namespace: cluster_kubernetes_namespace.namespace) { [policy.generate] }
        expect(kubeclient).to receive(:get_cilium_network_policies).with(namespace: cluster_kubernetes_namespace.namespace) { [cilium_policy.generate] }
        expect(kubeclient).to receive(:get_network_policies).with(namespace: cluster_kubernetes_namespace_2.namespace) { [policy_2.generate] }
        expect(kubeclient).to receive(:get_cilium_network_policies).with(namespace: cluster_kubernetes_namespace_2.namespace) { [] }
        expect(subject).to be_success
        expect(subject.payload.count).to eq(3)
        expect(subject.payload.map(&:as_json)).to include(policy.as_json, policy_2.as_json)
      end

      context 'with a partial successful response' do
        let(:error_message) { 'system failure' }

        before do
          allow(kubeclient).to receive(:get_network_policies).with(namespace: cluster_kubernetes_namespace.namespace).and_return([policy.generate])
          allow(kubeclient).to receive(:get_cilium_network_policies).with(namespace: cluster_kubernetes_namespace.namespace) { [] }
          allow(kubeclient).to receive(:get_network_policies).with(namespace: cluster_kubernetes_namespace_2.namespace).and_raise(Kubeclient::HttpError.new(500, error_message, nil))
        end

        it 'returns error response for the platforms with failures' do
          expect(subject).to be_error
          expect(subject.message).to match(error_message)
        end

        it 'returns error response with the policies for all successful platforms' do
          expect(subject).to be_error
          expect(subject.payload.count).to eq(1)
          expect(subject.payload.first.as_json).to eq(policy.as_json)
        end
      end
    end
  end
end
