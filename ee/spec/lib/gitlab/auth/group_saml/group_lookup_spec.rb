# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::GroupSaml::GroupLookup do
  let(:query_string) { 'group_path=the-group' }
  let(:path_info) { double }

  def subject(params = {})
    @subject ||= begin
      env = {
        "rack.input" => double,
        'PATH_INFO' => path_info
      }.merge(params)

      described_class.new(env)
    end
  end

  context 'on request path' do
    let(:path_info) { '/users/auth/group_saml' }

    it 'can detect group_path from rack.input body params' do
      subject('REQUEST_METHOD' => 'POST', 'rack.input' => StringIO.new(query_string), 'CONTENT_TYPE' => 'multipart/form-data')

      expect(subject.path).to eq 'the-group'
    end

    it 'can detect group_path from query params' do
      subject("QUERY_STRING" => query_string)

      expect(subject.path).to eq 'the-group'
    end
  end

  context 'on callback path' do
    let(:path_info) { '/groups/callback-group/-/saml/callback' }

    it 'can extract group_path from PATH_INFO' do
      expect(subject.path).to eq 'callback-group'
    end

    it 'does not allow params to take precedence' do
      subject("QUERY_STRING" => query_string)

      expect(subject.path).to eq 'callback-group'
    end
  end

  it 'looks up group by path' do
    group = create(:group)
    allow(subject).to receive(:path) { group.path }

    expect(subject.group).to be_a(Group)
  end

  it 'exposes saml_provider' do
    saml_provider = create(:saml_provider)
    allow(subject).to receive(:group) { saml_provider.group }

    expect(subject.saml_provider).to be_a(SamlProvider)
  end

  context 'on metadata path' do
    let(:path_info) { '/users/auth/group_saml/metadata' }
    let(:saml_provider) { create(:saml_provider) }
    let(:group) { saml_provider.group }
    let(:group_params) { { group_path: group.full_path } }

    describe '#token_discoverable?' do
      it 'returns false when missing the discovery token' do
        subject("QUERY_STRING" => group_params.to_query)

        expect(subject).not_to be_token_discoverable
      end

      it 'returns false for incorrect discovery token' do
        query_string = group_params.merge(token: 'wrongtoken').to_query
        subject("QUERY_STRING" => query_string)

        expect(subject).not_to be_token_discoverable
      end

      it 'returns true when discovery token matches' do
        query_string = group_params.merge(token: group.saml_discovery_token).to_query
        subject("QUERY_STRING" => query_string)

        expect(subject).to be_token_discoverable
      end
    end
  end
end
