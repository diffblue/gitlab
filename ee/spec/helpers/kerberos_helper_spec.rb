# frozen_string_literal: true

require 'spec_helper'
require 'gssapi'

RSpec.describe KerberosHelper do
  describe '#spnego_credentials!' do
    let(:gss) { double('GSSAPI::Simple') }
    let(:gss_service_name) { 'gss_service_name' }

    subject { Class.new { include KerberosHelper }.new }

    context 'with successful remote call' do
      before do
        expect(GSSAPI::Simple).to receive(:new)
          .with(nil, nil, ::Gitlab.config.kerberos.keytab)
          .and_return(gss)
      end

      shared_examples 'a method that decodes a spnego token' do
        let(:gss_result) { true }
        let(:spnego_response_token) { nil }

        it 'decodes the given spnego token' do
          token = 'abc123'
          gss_display_name = 'gss_display_name'

          expect(gss).to receive(:acquire_credentials).with(gss_service_name)
          expect(gss).to receive(:accept_context).with(token).and_return(gss_result)
          expect(gss).to receive(:display_name).and_return(gss_display_name)

          expect(subject.spnego_credentials!(token)).to eq(gss_display_name)
          expect(subject.spnego_response_token).to eq(spnego_response_token)
        end
      end

      context 'with Kerberos service_principal_name present' do
        before do
          kerberos_service_principal_name = 'default'
          stub_kerberos_setting(service_principal_name: kerberos_service_principal_name)
          expect(gss).to receive(:import_name).with(kerberos_service_principal_name).and_return(gss_service_name)
        end

        it_behaves_like 'a method that decodes a spnego token'

        context 'when gss_result is not true' do
          it_behaves_like 'a method that decodes a spnego token' do
            let(:gss_result) { 'gss_result' }
            let(:spnego_response_token) { gss_result }
          end
        end
      end

      context 'with Kerberos service_principal_name missing' do
        before do
          expect(gss).not_to receive(:import_name)
        end

        it_behaves_like 'a method that decodes a spnego token' do
          let(:gss_service_name) { nil }
        end
      end
    end

    context 'when the remote call fails' do
      before do
        allow(GSSAPI::Simple).to receive(:new)
          .with(nil, nil, ::Gitlab.config.kerberos.keytab)
          .and_raise(GSSAPI::GssApiError, 'a message')

        allow(Gitlab::AppLogger).to receive(:error).and_call_original
      end

      it 'fails to authenticate and logs an error' do
        expect(subject.spnego_credentials!('some token')).to eq(false)

        expect(Gitlab::AppLogger).to have_received(:error)
          .with(%r{failed to process Negotiate/Kerberos authentication: a message})
      end
    end
  end
end
