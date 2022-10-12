# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProductAnalytics::JitsuAuthentication do
  let(:jid) { '12345678' }
  let(:error_message) { '' }
  let(:jitsu_error_message) { '' }
  let_it_be(:project) { create(:project) }

  subject(:auth) { described_class.new(jid, project) }

  before do
    stub_application_setting(
      jitsu_host: 'http://jitsu.dev',
      jitsu_project_xid: 'testtesttesttestprj',
      jitsu_administrator_email: 'test@test.com',
      jitsu_administrator_password: 'testtest'
    )
  end

  shared_examples 'returns nil and logs the API error' do
    it do
      expect(Gitlab::AppLogger).to receive(:error).with(
        message: 'Jitsu API error',
        error: error_message,
        jitsu_error_message: jitsu_error_message,
        project_id: project.id,
        job_id: jid
      )
      expect(subject).to be_nil
    end
  end

  shared_examples 'returns nil and logs the exception' do
    it do
      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(instance_of(Gitlab::HTTP::Error))
      expect(subject).to be_nil
    end
  end

  describe '#generate_access_token' do
    subject { auth.generate_access_token }

    context 'when request is successful' do
      before do
        stub_signin_success
      end

      it { is_expected.to eq('thisisanaccesstoken') }
    end

    context 'when request is unsuccessful' do
      let(:error_message) { 'invalid password' }
      let(:jitsu_error_message) { 'Authorization failed: invalid password' }

      before do
        stub_signin_failure
      end

      it_behaves_like 'returns nil and logs the API error'
    end

    context 'when request throws an exception' do
      before do
        stub_signin_exception
      end

      it_behaves_like 'returns nil and logs the exception'
    end
  end

  describe '#create_api_key!' do
    subject { auth.create_api_key! }

    context 'when request is successful' do
      before do
        stub_signin_success
        stub_api_key_success
        allow(auth).to receive(:access_token).and_return('testtoken')
      end

      it { is_expected.to eq({ jsAuth: 'Mp1N4PYvRXNk1KIh2MLDE7BYghnSwdnt', uid: 'yijlmncqjot0xy9h6rv54p.s7zz20' }) }

      it do
        expect { subject }.to change(project.reload.project_setting, :jitsu_key).from(nil)
                                                                                .to('Mp1N4PYvRXNk1KIh2MLDE7BYghnSwdnt')
      end
    end

    context 'when request is unsuccessful' do
      let(:error_message) { 'token required' }
      let(:jitsu_error_message) { 'Authorization failed: token required' }

      before do
        stub_signin_success
        stub_api_key_failure
        allow(auth).to receive(:access_token).and_return('testtoken')
      end

      it_behaves_like 'returns nil and logs the API error'
    end

    context 'when request throws an exception' do
      before do
        stub_signin_success
        stub_api_key_exception
        allow(auth).to receive(:access_token).and_return('testtoken')
      end

      it_behaves_like 'returns nil and logs the exception'
    end
  end

  describe '#create_clickhouse_destination' do
    subject { auth.create_clickhouse_destination! }

    context 'when request is successful' do
      before do
        stub_signin_success
        stub_api_key_success
        stub_clickhouse_success
        allow(auth).to receive(:access_token).and_return('testtoken')
      end

      it { is_expected.not_to be_nil }
    end

    context 'when request is unsuccessful' do
      let(:error_message) { 'token required' }
      let(:jitsu_error_message) { 'Authorization failed: token required' }

      before do
        stub_signin_success
        stub_api_key_success
        stub_clickhouse_failure
        allow(auth).to receive(:access_token).and_return('testtoken')
      end

      it_behaves_like 'returns nil and logs the API error'
    end

    context 'when request throws an exception' do
      before do
        stub_signin_success
        stub_api_key_success
        stub_clickhouse_exception
        allow(auth).to receive(:access_token).and_return('testtoken')
      end

      it_behaves_like 'returns nil and logs the exception'
    end
  end

  private

  def stub_signin_success
    stub_request(:post, "http://jitsu.dev/api/v1/users/signin")
      .with(body: "{\"email\":\"test@test.com\",\"password\":\"testtest\"}")
      .to_return(status: 200, body: { access_token: 'thisisanaccesstoken' }.to_json, headers: {})
  end

  def stub_signin_failure
    stub_request(:post, "http://jitsu.dev/api/v1/users/signin")
      .with(body: "{\"email\":\"test@test.com\",\"password\":\"testtest\"}")
      .to_return(status: 401,
                 body: { error: 'invalid password', message: 'Authorization failed: invalid password' }.to_json,
                 headers: {})
  end

  def stub_signin_exception
    stub_request(:post, "http://jitsu.dev/api/v1/users/signin")
      .with(body: "{\"email\":\"test@test.com\",\"password\":\"testtest\"}")
      .to_raise(Gitlab::HTTP::Error)
  end

  def stub_api_key_success
    stub_request(:post, "http://jitsu.dev/api/v2/objects/testtesttesttestprj/api_keys")
      .to_return(status: 200,
                 body: "{\"jsAuth\":\"Mp1N4PYvRXNk1KIh2MLDE7BYghnSwdnt\",\"uid\":\"yijlmncqjot0xy9h6rv54p.s7zz20\"}",
                 headers: {})
  end

  def stub_api_key_failure
    stub_request(:post, "http://jitsu.dev/api/v2/objects/testtesttesttestprj/api_keys")
      .to_return(status: 401,
                 body: { error: 'token required', message: 'Authorization failed: token required' }.to_json,
                 headers: {})
  end

  def stub_api_key_exception
    stub_request(:post, "http://jitsu.dev/api/v2/objects/testtesttesttestprj/api_keys")
      .to_raise(Gitlab::HTTP::Error)
  end

  def stub_clickhouse_success
    stub_request(:post, "http://jitsu.dev/api/v2/objects/testtesttesttestprj/destinations")
      .to_return(status: 200)
  end

  def stub_clickhouse_failure
    stub_request(:post, "http://jitsu.dev/api/v2/objects/testtesttesttestprj/destinations")
      .to_return(status: 401,
                 body: { error: 'token required', message: 'Authorization failed: token required' }.to_json,
                 headers: {})
  end

  def stub_clickhouse_exception
    stub_request(:post, "http://jitsu.dev/api/v2/objects/testtesttesttestprj/destinations")
      .to_raise(Gitlab::HTTP::Error)
  end
end
