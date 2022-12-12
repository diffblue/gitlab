# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Auth::Smartcard::SANExtension do
  let(:fqdn) { 'gitlab.example.com' }
  let(:extension_factory) { OpenSSL::X509::ExtensionFactory.new(nil, cert) }
  let(:san_extension) { described_class.new(cert, fqdn) }

  let(:cert) do
    key = OpenSSL::PKey::RSA.new 2048
    name = OpenSSL::X509::Name.parse 'CN=nobody/DC=example'

    cert = OpenSSL::X509::Certificate.new
    cert.version = 3
    cert.serial = 0
    cert.not_before = Time.current
    cert.not_after = Time.current + 3600
    cert.public_key = key.public_key
    cert.subject = name
    cert
  end

  def add_san_entry(value)
    cert.add_extension extension_factory.create_extension('subjectAltName', value)
  end

  describe '#alternate_emails' do
    subject { san_extension.alternate_emails }

    context 'without SAN extensions' do
      it { is_expected.to be_empty }
    end

    context 'with SAN extensions' do
      describe 'single extension' do
        let(:uri) { 'https://gitlab.example.com' }

        before do
          add_san_entry "URI:#{uri}"
        end

        it { is_expected.to match([{ described_class::URI_TAG => uri }]) }
      end

      describe 'multiple entries using ASN1' do
        let(:email) { 'my@other.address' }
        let(:uri) { '1.2.3.4' }

        before do
          add_san_entry "email:#{email},URI:#{uri}"
        end

        it {
          is_expected.to match([{
                                  described_class::EMAIL_TAG => email,
                                  described_class::URI_TAG => uri
                                }])
        }
      end

      describe 'custom General Name' do
        it 'can\'t use custom alt names that are not part of general names' do
          expect { add_san_entry 'customName:some@gitlab.com' }
            .to raise_error OpenSSL::X509::ExtensionError
        end
      end
    end
  end

  describe '#email_identity' do
    let(:san_single_email) { 'singleEntryEmail@some.domain' }

    before do
      allow(Gitlab.config.gitlab).to receive(:host).and_return(fqdn)
      add_san_entry "email:#{san_single_email}"
    end

    subject { san_extension.email_identity }

    it { is_expected.to eq san_single_email }

    context 'multiple email identity SAN entries' do
      let(:san_email) { 'newemail@some.domain' }
      let(:san_uri) { 'not.yourdomain.com' }

      before do
        add_san_entry "email:#{san_email},URI:#{san_uri}"
      end

      describe 'alternate name email for GitLab defined in the certificate' do
        let(:san_uri) { "https://#{fqdn}" }

        it { is_expected.to eq san_email }

        context 'inappropriate URI format' do
          let(:san_uri) { 'an invalid uri' }

          it { is_expected.to be_nil }
        end
      end

      context 'no alternate name defined to use with GitLab' do
        it { is_expected.to be_nil }
      end

      context 'when the host is partially matched to the URI' do
        let(:uri) { "https://#{fqdn}.anotherdomain.com" }
        let(:identity) { 'user@email.com' }

        before do
          add_san_entry "email:#{identity},URI:#{uri}"
        end

        it { is_expected.to be_nil }
      end
    end
  end
end
