# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Github::StatusNotifier do
  let(:access_token) { 'aaaaa' }
  let(:repo_path) { 'myself/my-project' }

  subject { described_class.new(access_token, repo_path) }

  describe '#notify' do
    let(:ref) { 'master' }
    let(:state) { 'pending' }
    let(:params) { { context: 'Gitlab' } }
    let(:github_status_api) { "https://api.github.com/repos/#{repo_path}/statuses/#{ref}" }

    let(:response_headers) { { 'Content-Type' => 'application/json' } }
    let(:response) do
      {
        url: github_status_api,
        id: 1,
        node_id: 'MDY6U3RhdHVzMQ==',
        state: 'success',
        description: 'Build has completed successfully',
        target_url: 'https://ci.example.com/1000/output',
        context: 'continuous-integration/jenkins',
        created_at: '2012-07-20T01:19:13Z',
        updated_at: '2012-07-20T01:19:13Z',
        creator: {
          login: 'octocat',
          id: 1
        }
      }
    end

    it 'uses GitHub API to update status and returns the result as a hash' do
      stub_request(:post, github_status_api).to_return(status: 200, body: response.to_json, headers: response_headers)

      result = subject.notify(ref, state)

      expect(a_request(:post, github_status_api)).to have_been_made.once
      expect(result).to be_a(Hash)
    end

    context 'with blank api_endpoint' do
      let(:api_endpoint) { '' }

      subject { described_class.new(access_token, repo_path, api_endpoint: api_endpoint) }

      it 'defaults to using GitHub.com API' do
        github_status_api = "https://api.github.com/repos/#{repo_path}/statuses/#{ref}"
        stub_request(:post, github_status_api).to_return(status: 200, body: response.to_json, headers: response_headers)

        subject.notify(ref, state)

        expect(a_request(:post, github_status_api)).to have_been_made.once
      end
    end

    context 'with custom api_endpoint' do
      let(:api_endpoint) { 'https://my.code.repo' }

      subject { described_class.new(access_token, repo_path, api_endpoint: api_endpoint) }

      it 'uses provided API for requests' do
        custom_status_api = "https://my.code.repo/repos/#{repo_path}/statuses/#{ref}"
        stub_request(:post, custom_status_api).to_return(status: 200, body: response.to_json, headers: response_headers)

        subject.notify(ref, state)

        expect(a_request(:post, custom_status_api)).to have_been_made.once
      end
    end

    it 'passes optional params' do
      expect_context = hash_including(context: 'My Context')
      stub_request(:post, github_status_api).with(body: expect_context)
        .to_return(status: 200, body: response.to_json, headers: response_headers)

      subject.notify(ref, state, context: 'My Context')

      expect(a_request(:post, github_status_api)).to have_been_made.once
    end

    it 'uses access token' do
      auth_header = { 'Authorization' => 'token aaaaa' }
      stub_request(:post, github_status_api).with(headers: auth_header)
        .to_return(status: 200, body: response.to_json, headers: response_headers)

      subject.notify(ref, state)

      expect(a_request(:post, github_status_api)).to have_been_made.once
    end
  end
end
