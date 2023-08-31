# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::AppliedMl::SuggestedReviewers::Client, feature_category: :code_review_workflow do
  include AfterNextHelpers

  let(:stub_class) { Gitlab::AppliedMl::SuggestedReviewers::RecommenderServicesPb::Stub }

  let(:rpc_url) { 'example.org:1234' }
  let(:certs) { 'arandomstring' }
  let(:secret) { SecureRandom.hex(32) }
  let(:client_arguments) { {} }

  let(:client) { described_class.new(**client_arguments) }

  shared_examples 'respecting channel credentials' do
    it 'uses a ChannelCredentials object' do
      allow(GRPC::Core::ChannelCredentials).to receive(:new).and_call_original

      subject

      expect(stub_class).to have_received(:new)
                              .with(
                                rpc_url,
                                instance_of(GRPC::Core::ChannelCredentials),
                                timeout: described_class::DEFAULT_TIMEOUT
                              )
    end

    it 'uses a CallCredentials object' do
      allow(GRPC::Core::CallCredentials).to receive(:new).and_call_original

      subject

      expect(GRPC::Core::CallCredentials).to have_received(:new).with(instance_of(Proc))
    end

    it 'creates a JWT HMAC token', :aggregate_failures do
      token = instance_spy(JSONWebToken::HMACToken, encoded: 'test-token')
      allow(JSONWebToken::HMACToken).to receive(:new).with(secret).and_return(token)

      subject

      expect(token).to have_received(:issuer=).with(described_class::JWT_ISSUER)
      expect(token).to have_received(:audience=).with(described_class::JWT_AUDIENCE)
      expect(token).to have_received(:encoded)
    end
  end

  shared_examples 'respecting environment configuration' do
    it 'uses a development URL' do
      allow(Gitlab).to receive(:dev_or_test_env?).and_return(true)

      subject

      expect(stub_class).to have_received(:new).with('suggested-reviewer.dev:443', any_args)
    end

    it 'uses a production URL' do
      allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)

      subject

      expect(stub_class).to have_received(:new).with('api.unreview.io:443', any_args)
    end

    context 'with an invalid gRPC URL configured' do
      let(:client_arguments) { { rpc_url: '' } }

      it 'raises a configuration error' do
        expect { subject }.to raise_error(Gitlab::AppliedMl::Errors::ConfigurationError, 'gRPC host unknown')
      end
    end

    context 'with no secret configured' do
      let(:secret) { nil }

      it 'raises a configuration error' do
        expect { subject }.to raise_error(Gitlab::AppliedMl::Errors::ConfigurationError,
          'Variable SUGGESTED_REVIEWERS_SECRET is missing')
      end
    end

    context 'with an invalid secret configured' do
      let(:secret) { '@s3cr3tunt0ld' }

      it 'raises a configuration error' do
        expect { subject }.to raise_error(Gitlab::AppliedMl::Errors::ConfigurationError, 'Secret must contain 64 bytes')
      end
    end
  end

  describe '#suggested_reviewers' do
    let(:response_class) { Gitlab::AppliedMl::SuggestedReviewers::RecommenderPb::MergeRequestRecommendationsResV2 }

    let(:suggested_reviewers_request) do
      {
        project_id: 42,
        merge_request_iid: 7,
        top_n: 5,
        changes: ['db', 'ee/db'],
        author_username: 'joe'
      }
    end

    let(:suggested_reviewers_response) do
      response_class.new(
        {
          version: "0.7.1",
          top_n: 4,
          reviewers: %w[john jane]
        }
      )
    end

    subject do
      client.suggested_reviewers(**suggested_reviewers_request)
    end

    before do
      stub_env('SUGGESTED_REVIEWERS_SECRET', secret)
    end

    context 'when configuration and input is healthy' do
      let(:client_arguments) { { rpc_url: rpc_url, certs: certs } }
      let(:suggested_reviewers_result) do
        {
          version: "0.7.1",
          top_n: 4,
          reviewers: %w[john jane]
        }
      end

      before do
        allow_next_instance_of(stub_class) do |stub|
          allow(stub).to receive(:merge_request_recommendations_v2).and_return(suggested_reviewers_response)
        end
      end

      it { is_expected.to eq(suggested_reviewers_result) }

      it_behaves_like 'respecting channel credentials'
    end

    context 'when a grpc connection error is received' do
      before do
        allow_next_instance_of(stub_class) do |stub|
          allow(stub).to receive(:merge_request_recommendations_v2).and_raise(GRPC::Unavailable)
        end
      end

      it 'raises a new error' do
        expect { subject }.to raise_error(Gitlab::AppliedMl::Errors::ConnectionFailed)
      end
    end

    context 'when a grpc bad status is received' do
      before do
        allow_next_instance_of(stub_class) do |stub|
          allow(stub).to receive(:merge_request_recommendations_v2).and_raise(GRPC::Internal)
        end
      end

      it 'raises a new error' do
        expect { subject }.to raise_error(Gitlab::AppliedMl::Errors::ResourceNotAvailable)
      end
    end

    context 'with no changes' do
      let(:suggested_reviewers_request) do
        {
          project_id: 42,
          merge_request_iid: 7,
          top_n: 5,
          changes: [],
          author_username: 'joe'
        }
      end

      it 'raises a new error' do
        expect { subject }.to raise_error(Gitlab::AppliedMl::Errors::ArgumentError)
      end
    end

    describe 'gRPC configuration' do
      let(:client_arguments) { {} }

      before do
        allow_next_instance_of(stub_class) do |stub|
          allow(stub).to receive(:merge_request_recommendations_v2).and_return(suggested_reviewers_response)
        end
      end

      it_behaves_like 'respecting environment configuration'
    end
  end

  describe '#register_project' do
    let(:response_class) { Gitlab::AppliedMl::SuggestedReviewers::RecommenderPb::RegisterProjectRes }
    let(:register_project_request) do
      {
        project_id: 42,
        project_name: 'foo',
        project_namespace: 'bar/zoo',
        access_token: 'secret'
      }
    end

    let(:register_project_response) do
      response_class.new(
        {
          project_id: 42,
          registered_at: '2022-01-01 20:22'
        }
      )
    end

    subject do
      client.register_project(**register_project_request)
    end

    before do
      stub_env('SUGGESTED_REVIEWERS_SECRET', secret)
    end

    context 'when configuration and input is healthy' do
      let(:client_arguments) { { rpc_url: rpc_url, certs: certs } }
      let(:register_project_result) do
        {
          project_id: 42,
          registered_at: '2022-01-01 20:22'
        }
      end

      before do
        allow_next_instance_of(stub_class) do |stub|
          allow(stub).to receive(:register_project).and_return(register_project_response)
        end
      end

      it { is_expected.to eq(register_project_result) }

      it_behaves_like 'respecting channel credentials'
    end

    context 'when a grpc already exists is received' do
      before do
        allow_next_instance_of(stub_class) do |stub|
          allow(stub).to receive(:register_project).and_raise(GRPC::AlreadyExists)
        end
      end

      it 'raises a new error' do
        expect { subject }.to raise_error(Gitlab::AppliedMl::Errors::ProjectAlreadyExists)
      end
    end

    context 'when a grpc bad status is received' do
      before do
        allow_next_instance_of(stub_class) do |stub|
          allow(stub).to receive(:register_project).and_raise(GRPC::Unavailable)
        end
      end

      it 'raises a new error' do
        expect { subject }.to raise_error(Gitlab::AppliedMl::Errors::ResourceNotAvailable)
      end
    end

    describe 'with gRPC configuration' do
      let(:client_arguments) { {} }

      before do
        allow_next_instance_of(stub_class) do |stub|
          allow(stub).to receive(:register_project).and_return(register_project_response)
        end
      end

      it_behaves_like 'respecting environment configuration'
    end
  end

  describe '#deregister_project' do
    let(:response_class) { Gitlab::AppliedMl::SuggestedReviewers::RecommenderPb::DeregisterProjectRes }
    let(:deregister_project_request) do
      {
        project_id: 42
      }
    end

    let(:deregister_project_response) do
      response_class.new(
        {
          project_id: 42,
          deregistered_at: '2022-01-01 20:22'
        }
      )
    end

    subject do
      client.deregister_project(**deregister_project_request)
    end

    before do
      stub_env('SUGGESTED_REVIEWERS_SECRET', secret)
    end

    context 'when configuration and input is healthy' do
      let(:client_arguments) { { rpc_url: rpc_url, certs: certs } }
      let(:deregister_project_result) do
        {
          project_id: 42,
          deregistered_at: '2022-01-01 20:22'
        }
      end

      before do
        allow_next(stub_class).to receive(:deregister_project).and_return(deregister_project_response)
      end

      it { is_expected.to eq(deregister_project_result) }

      it_behaves_like 'respecting channel credentials'
    end

    context 'when a grpc not found is received' do
      before do
        allow_next(stub_class).to receive(:deregister_project).and_raise(GRPC::NotFound)
      end

      it 'raises a new error' do
        expect { subject }.to raise_error(Gitlab::AppliedMl::Errors::ProjectNotFound)
      end
    end

    context 'when a grpc bad status is received' do
      before do
        allow_next(stub_class).to receive(:deregister_project).and_raise(GRPC::Unavailable)
      end

      it 'raises a new error' do
        expect { subject }.to raise_error(Gitlab::AppliedMl::Errors::ResourceNotAvailable)
      end
    end

    describe 'with gRPC configuration' do
      let(:client_arguments) { {} }

      before do
        allow_next(stub_class).to receive(:deregister_project).and_return(deregister_project_response)
      end

      it_behaves_like 'respecting environment configuration'
    end
  end
end
