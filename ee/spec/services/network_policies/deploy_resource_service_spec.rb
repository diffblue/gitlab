# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NetworkPolicies::DeployResourceService do
  let(:service) { NetworkPolicies::DeployResourceService.new(resource_name: resource_name, manifest: manifest, environment: environment, enabled: enabled) }
  let(:environment) { instance_double('Environment', deployment_platform: platform, deployment_namespace: 'namespace') }
  let(:platform) { instance_double('Clusters::Platforms::Kubernetes', kubeclient: kubeclient) }
  let(:kubeclient) { double('Kubeclient::Client') }
  let(:enabled) { nil }
  let(:resource_name) { nil }
  let(:policy) do
    Gitlab::Kubernetes::NetworkPolicy.new(
      name: 'policy',
      namespace: 'another',
      selector: { matchLabels: { role: 'db' } },
      ingress: [{ from: [{ namespaceSelector: { matchLabels: { project: 'myproject' } } }] }]
    )
  end

  let(:manifest) do
    <<~POLICY
      apiVersion: networking.k8s.io/v1
      kind: NetworkPolicy
      metadata:
        name: policy
        namespace: another
      spec:
        podSelector:
          matchLabels:
            role: db
        policyTypes:
        - Ingress
        ingress:
        - from:
          - namespaceSelector:
              matchLabels:
                project: myproject
    POLICY
  end

  include_examples 'different network policy types'

  before do
    allow(Gitlab::Kubernetes::NetworkPolicy).to receive(:from_resource).and_return policy
    allow(Gitlab::Kubernetes::NetworkPolicy).to receive(:from_yaml).and_return policy
  end

  describe '#execute' do
    subject { service.execute }

    it 'creates resource in the deployment namespace and return success response with a policy' do
      namespaced_policy = policy.generate
      namespaced_policy[:metadata][:namespace] = environment.deployment_namespace

      expect(kubeclient).to receive(:create_network_policy).with(namespaced_policy) { policy.generate }
      expect(subject).to be_success
      expect(subject.payload.as_json).to eq(policy.as_json)
    end

    context 'with resource_name' do
      let(:resource_name) { 'policy' }

      context 'when name is not updated' do
        it 'updates resource in the deployment namespace and returns success response with a policy' do
          namespaced_policy = policy.generate
          namespaced_policy[:metadata][:namespace] = environment.deployment_namespace

          expect(kubeclient).to receive(:update_network_policy).with(namespaced_policy)
          expect(subject).to be_success
          expect(subject.payload.as_json).to eq(policy.as_json)
        end
      end

      context 'when name is updated' do
        let(:policy) do
          Gitlab::Kubernetes::NetworkPolicy.new(
            name: 'policy2',
            namespace: 'another',
            selector: { matchLabels: { role: 'db' } },
            ingress: [{ from: [{ namespaceSelector: { matchLabels: { project: 'myproject' } } }] }]
          )
        end

        it 'destroys and recreates resource in the deployment namespace and returns success response with a policy' do
          namespaced_policy = policy.generate
          namespaced_policy[:metadata][:namespace] = environment.deployment_namespace
          namespaced_policy[:metadata][:resourceVersion] = nil

          expect(kubeclient).to receive(:delete_network_policy).with(resource_name, environment.deployment_namespace)
          expect(kubeclient).to receive(:create_network_policy).with(namespaced_policy)
          expect(subject).to be_success
          expect(subject.payload.as_json).to eq(policy.as_json)
        end
      end
    end

    context 'without manifest' do
      let(:manifest) { nil }
      let(:policy) { nil }

      it 'returns error response' do
        expect(subject).to be_error
        expect(subject.http_status).to eq(:bad_request)
        expect(subject.message).not_to be_nil
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

    include_examples 'responds to Kubeclient::HttpError', :create_network_policy

    context 'with cilium network policy' do
      let(:manifest) do
        <<~POLICY
          apiVersion: cilium.io/v2
          kind: CiliumNetworkPolicy
          metadata:
            name: policy
            namespace: another
            resourceVersion: 101
          spec:
            endpointSelector:
              matchLabels:
                role: db
            ingress:
            - fromEndpoints:
              - matchLabels:
                  project: myproject
        POLICY
      end

      let(:policy) do
        Gitlab::Kubernetes::CiliumNetworkPolicy.new(
          name: 'policy',
          namespace: 'namespace',
          resource_version: 101,
          selector: { matchLabels: { role: 'db' } },
          ingress: [{ fromEndpoints: [{ matchLabels: { project: 'myproject' } }] }]
        )
      end

      it 'creates resource in the deployment namespace and return success response with a policy' do
        namespaced_policy = policy.generate
        namespaced_policy[:metadata][:namespace] = environment.deployment_namespace

        expect(kubeclient).to receive(:create_cilium_network_policy).with(namespaced_policy) { policy.generate }
        expect(subject).to be_success
        expect(subject.payload.as_json).to eq(policy.as_json)
      end

      context 'with resource_name' do
        let(:resource_name) { 'policy' }

        before do
          allow(Gitlab::Kubernetes::CiliumNetworkPolicy).to receive(:from_resource).and_return policy
          allow(Gitlab::Kubernetes::CiliumNetworkPolicy).to receive(:from_yaml).and_return policy
        end

        context 'when name is not updated' do
          it 'updates resource in the deployment namespace and returns success response with a policy' do
            namespaced_policy = policy.generate
            namespaced_policy[:metadata][:namespace] = environment.deployment_namespace

            expect(kubeclient).to receive(:update_cilium_network_policy).with(namespaced_policy)
            expect(subject).to be_success
            expect(subject.payload.as_json).to eq(policy.as_json)
          end
        end

        context 'when name is updated' do
          let(:policy) do
            Gitlab::Kubernetes::CiliumNetworkPolicy.new(
              name: 'policy2',
              namespace: 'namespace',
              resource_version: 101,
              selector: { matchLabels: { role: 'db' } },
              ingress: [{ fromEndpoints: [{ matchLabels: { project: 'myproject' } }] }]
            )
          end

          let(:manifest) do
            <<~POLICY
              apiVersion: cilium.io/v2
              kind: CiliumNetworkPolicy
              metadata:
                name: policy2
                namespace: another
                resourceVersion: 101
              spec:
                endpointSelector:
                  matchLabels:
                    role: db
                ingress:
                - fromEndpoints:
                  - matchLabels:
                      project: myproject
            POLICY
          end

          it 'destroys and recreates resource in the deployment namespace and returns success response with a policy' do
            namespaced_policy = policy.generate
            namespaced_policy[:metadata][:namespace] = environment.deployment_namespace
            namespaced_policy[:metadata][:resourceVersion] = nil

            expect(kubeclient).to receive(:delete_cilium_network_policy).with(resource_name, environment.deployment_namespace)
            expect(kubeclient).to receive(:create_cilium_network_policy).with(namespaced_policy)
            expect(subject).to be_success
            expect(subject.payload.as_json).to eq(policy.as_json)
          end
        end
      end
    end

    context 'with enabled set to true' do
      let(:enabled) { true }

      it 'enables policy before deploying it' do
        expect(policy).to receive(:enable)
        expect(kubeclient).to receive(:create_network_policy) { policy.generate }
        expect(subject).to be_success
      end
    end

    context 'with enabled set to false' do
      let(:enabled) { false }

      it 'disables policy before deploying it' do
        expect(policy).to receive(:disable)
        expect(kubeclient).to receive(:create_network_policy) { policy.generate }
        expect(subject).to be_success
      end
    end
  end
end
