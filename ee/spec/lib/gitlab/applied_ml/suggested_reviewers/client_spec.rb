# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::AppliedMl::SuggestedReviewers::Client do
  let(:stub_class) { Gitlab::AppliedMl::SuggestedReviewers::RecommenderServicesPb::Stub }
  let(:response_class) { Gitlab::AppliedMl::SuggestedReviewers::RecommenderPb::MergeRequestRecommendationsResV2 }

  let(:rpc_url) { 'example.org:1234' }
  let(:certs) { 'arandomstring' }
  let(:secret) { SecureRandom.hex(32) }
  let(:client_arguments) { {} }

  let(:client) { described_class.new(**client_arguments) }

  describe '#suggested_reviewers' do
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

    context 'when a grpc bad status is received' do
      before do
        allow_next_instance_of(stub_class) do |stub|
          allow(stub).to receive(:merge_request_recommendations_v2).and_raise(GRPC::Unavailable)
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

    context 'with no gRPC URL configured' do
      let(:client_arguments) { {} }

      before do
        allow_next_instance_of(stub_class) do |stub|
          allow(stub).to receive(:merge_request_recommendations_v2).and_return(suggested_reviewers_response)
        end
      end

      context 'when on dev or test environment' do
        before do
          allow(Gitlab).to receive(:dev_or_test_env?).and_return(true)
        end

        it 'uses a development URL' do
          subject

          expect(stub_class).to have_received(:new).with('suggested-reviewer.dev:443', any_args)
        end
      end

      context 'when not on dev or test environment' do
        before do
          allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)
        end

        it 'uses a production URL' do
          subject

          expect(stub_class).to have_received(:new).with('api.unreview.io:443', any_args)
        end
      end
    end

    context 'with an invalid gRPC URL configured' do
      let(:client_arguments) { { rpc_url: '' } }

      it 'raises a configuration error' do
        expect { subject }.to raise_error(Gitlab::AppliedMl::Errors::ConfigurationError)
      end
    end

    context 'with no secret configured' do
      let(:secret) { nil }

      it 'raises a configuration error' do
        expect { subject }.to raise_error(Gitlab::AppliedMl::Errors::ConfigurationError)
      end
    end

    context 'with an invalid secret configured' do
      let(:secret) { '@s3cr3tunt0ld' }

      it 'raises a configuration error' do
        expect { subject }.to raise_error(Gitlab::AppliedMl::Errors::ConfigurationError)
      end
    end
  end
end
