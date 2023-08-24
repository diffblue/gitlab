# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DependencyProxy::Packages::Maven::VerifyPackageFileEtagService, :aggregate_failures, feature_category: :package_registry do
  let_it_be(:setting) { create(:dependency_proxy_packages_setting, :maven) }
  let_it_be(:package_file) { create(:package_file, :jar) }

  let(:remote_url) { "http://#{setting.maven_external_registry_username}:#{setting.maven_external_registry_password}@test/package.file" }

  let(:authorization_header) do
    ActionController::HttpAuthentication::Basic.encode_credentials(
      setting.maven_external_registry_username,
      setting.maven_external_registry_password
    )
  end

  let(:service) do
    described_class.new(remote_url: remote_url, package_file: package_file)
  end

  describe '#execute' do
    subject(:result) { service.execute }

    shared_examples 'expecting a service response error with' do |message:, reason:|
      it 'returns an error' do
        if message.start_with?('Received')
          expect(Gitlab::AppLogger).to receive(:error).with(
            service_class: described_class.to_s,
            project_id: package_file.package.project_id,
            message: message
          )
        end

        expect(result).to be_a(ServiceResponse)
        expect(result).to be_error
        expect(result.message).to eq(message)
        expect(result.reason).to eq(reason)
      end
    end

    context 'with valid arguments' do
      context 'with a successful head request' do
        it 'returns a successful service response' do
          stub_external_registry_request(status: 200, etag: package_file.file_md5)

          expect(result).to be_a(ServiceResponse)
          expect(result).to be_success
        end

        context 'with an unmatched etag' do
          before do
            stub_external_registry_request(status: 200, etag: 'wrong_etag')
          end

          it_behaves_like 'expecting a service response error with',
            message: "etag from external registry doesn't match any known digests",
            reason: :wrong_etag
        end

        context 'with a redirect' do
          let(:redirect_location) { 'http://redirect' }

          it 'follows it' do
            stub_external_registry_request(status: 307, response_headers: { Location: redirect_location })
            stub_request(:head, redirect_location)
              .to_return(status: 200, body: '', headers: { etag: "\"#{package_file.file_md5}\"" })

            expect(result).to be_a(ServiceResponse)
            expect(result).to be_success
          end
        end
      end

      context 'with a unsuccessful head request' do
        before do
          stub_external_registry_request(status: 404)
        end

        it_behaves_like 'expecting a service response error with',
          message: 'Received 404 from external registry',
          reason: :response_error_code
      end

      context 'with a timeout' do
        before do
          allow(::Gitlab::HTTP).to receive(:head).and_raise(::Timeout::Error)
        end

        it_behaves_like 'expecting a service response error with',
          message: 'Received 599 from external registry',
          reason: :response_error_code
      end
    end

    context 'with invalid arguments' do
      %i[remote_url package_file].each do |field|
        context "with a nil #{field}" do
          let(field) { nil }

          it_behaves_like 'expecting a service response error with',
            message: 'invalid arguments',
            reason: :invalid_arguments
        end
      end
    end

    def stub_external_registry_request(status: 200, etag: 'etag', response_headers: {})
      stub_request(:head, 'http://test/package.file')
        .with(
          headers: { 'Authorization' => authorization_header }
        ).to_return(status: status, body: '', headers: response_headers.merge(etag: "\"#{etag}\""))
    end
  end
end
