# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::AppliedMl::SuggestedReviewers::Client do
  let(:rpc_url) { 'example.org:1234' }
  let(:certs) { 'arandomstring' }
  let(:stub_class) { Gitlab::AppliedMl::SuggestedReviewers::RecommenderServicesPb::Stub }
  let(:response_class) { Gitlab::AppliedMl::SuggestedReviewers::RecommenderPb::MergeRequestRecommendationsResV2 }

  let(:client) { described_class.new(rpc_url: rpc_url, certs: certs) }

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

    subject do
      client.suggested_reviewers(**suggested_reviewers_request)
    end

    context 'when configuration and input is healthy' do
      let(:suggested_reviewers_result) do
        {
          version: "0.7.1",
          top_n: 4,
          reviewers: %w[john jane]
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
    end

    context 'when a grpc bad status is received' do
      before do
        allow_next_instance_of(stub_class) do |stub|
          allow(stub).to receive(:merge_request_recommendations_v2).and_raise(GRPC::Unavailable)
        end
      end

      it 'raises a new error', :aggregate_failures do
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
      let(:rpc_url) { '' }

      it 'logs and raises a new error' do
        expect { subject }.to raise_error(Gitlab::AppliedMl::Errors::ConfigurationError)
      end
    end
  end
end
