# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StatusPage::ProjectSetting do
  describe 'associations' do
    it { is_expected.to belong_to(:project).inverse_of(:status_page_setting) }
  end

  describe 'validations' do
    it { is_expected.not_to validate_presence_of(:status_page_url) }
    it { is_expected.to validate_presence_of(:aws_s3_bucket_name) }
    it { is_expected.to validate_length_of(:aws_s3_bucket_name).is_at_least(3).is_at_most(63) }
    it { is_expected.to validate_presence_of(:aws_region) }
    it { is_expected.to validate_presence_of(:aws_access_key) }
    it { is_expected.to validate_presence_of(:encrypted_aws_secret_key) }

    describe 'status_page_url' do
      it 'disallows invalid urls for status_page_url' do
        unsafe_url = %{https://replaceme.com/'><script>alert(document.cookie)</script>}
        non_ascii_url = 'http://status€.gitlab.com'
        blank_url = ''
        excessively_long_url = 'https://statu' + 's' * 1024 + '.com'

        is_expected.not_to allow_values(
          unsafe_url,
          non_ascii_url,
          blank_url,
          excessively_long_url
        ).for(:status_page_url)
      end

      it 'allows valid urls for status_page_url' do
        external_url = 'http://status.gitlab.com/'
        internal_url = 'http://192.168.1.1'

        is_expected.to allow_value(
          external_url,
          internal_url
        ).for(:status_page_url)
      end
    end

    describe 'aws_s3_bucket_name' do
      it { is_expected.to allow_value('bucket-name').for(:aws_s3_bucket_name) }
      it { is_expected.to allow_value('3ucket-name').for(:aws_s3_bucket_name) }
      it { is_expected.to allow_value('bucket.name').for(:aws_s3_bucket_name) }
      it { is_expected.to allow_value('b' * 63).for(:aws_s3_bucket_name) }
      it { is_expected.to allow_value('1' * 63).for(:aws_s3_bucket_name) }
      it { is_expected.not_to allow_value('Bucket-name').for(:aws_s3_bucket_name) }
      it { is_expected.not_to allow_value('bucKet-Name').for(:aws_s3_bucket_name) }
      it { is_expected.not_to allow_value('bb').for(:aws_s3_bucket_name) }
      it { is_expected.not_to allow_value('b' * 64).for(:aws_s3_bucket_name) }
    end

    describe 'aws_access_key' do
      it { is_expected.to allow_value('A' * 20).for(:aws_access_key) }
      it { is_expected.to allow_value('1' * 20).for(:aws_access_key) }
      it { is_expected.not_to allow_value('A' * 19).for(:aws_access_key) }
      it { is_expected.not_to allow_value('1' * 19).for(:aws_access_key) }
      it { is_expected.not_to allow_value('A' * 21).for(:aws_access_key) }
      it { is_expected.not_to allow_value('1' * 21).for(:aws_access_key) }
    end

    describe 'aws_secret_key' do
      let(:status_page_setting) { build(:status_page_setting) }

      it 'tests the validation' do
        expect(status_page_setting.valid?).to eq(true)

        status_page_setting.aws_secret_key = 'a' * 40
        expect(status_page_setting.valid?).to eq(true)

        status_page_setting.aws_secret_key = 'a' * 39
        expect(status_page_setting.valid?).to eq(false)

        status_page_setting.aws_secret_key = 'a' * 41
        expect(status_page_setting.valid?).to eq(false)
      end

      context 'existing setting' do
        let(:status_page_setting) { create(:status_page_setting) }

        it 'passes validation and removes changes if setting to masked key' do
          status_page_setting.aws_secret_key = status_page_setting.masked_aws_secret_key
          expect(status_page_setting.valid?).to eq(true)
        end
      end
    end
  end

  describe 'attribute encryption' do
    let(:new_secret) { FFaker::String.from_regexp(StatusPage::ProjectSetting::AWS_SECRET_KEY_REGEXP) }

    subject(:status_page_setting) { create(:status_page_setting, aws_secret_key: new_secret) }

    context 'token' do
      it 'encrypts original value into encrypted_token attribute' do
        expect(status_page_setting.encrypted_aws_secret_key).not_to be_nil
      end
    end
  end

  describe '#masked_aws_secret_key' do
    let(:status_page_setting) { build(:status_page_setting) }

    subject { status_page_setting.masked_aws_secret_key }

    it { is_expected.to eq('*' * 40) }

    context 'when no secret saved' do
      let(:status_page_setting) { build(:status_page_setting, aws_secret_key: nil) }

      it { is_expected.to eq(nil) }
    end
  end

  describe '#enabled?' do
    let(:status_page_setting) { build(:status_page_setting, :enabled) }

    subject { status_page_setting.enabled? }

    before do
      stub_licensed_features(status_page: true)
    end

    it { is_expected.to eq(true) }

    context 'when status page setting is disabled' do
      before do
        status_page_setting.enabled = false
      end

      it { is_expected.to eq(false) }
    end

    context 'when license is not available' do
      before do
        stub_licensed_features(status_page: false)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '#normalized_status_page_url' do
    let(:status_page_setting) { build(:status_page_setting, status_page_url: status_page_url) }
    let(:status_page_url) { 'https://status.gitlab.com' }
    let(:expected_url) { 'https://status.gitlab.com/#/' }

    subject { status_page_setting.normalized_status_page_url }

    context 'when status_page_url exists' do
      it { is_expected.to eq(expected_url) }
    end

    context 'when status_page_url is blank' do
      let(:status_page_url) { '' }

      it { is_expected.to be_nil }
    end

    context 'when status_page_url is nil' do
      let(:status_page_url) { nil }

      it { is_expected.to be_nil }
    end

    context 'when status_page_url contains trailing slash' do
      let(:status_page_url) { 'https://status.gitlab.com/' }

      it { is_expected.to eq(expected_url) }
    end

    context 'when status_page_url contains trailing hash-navigator' do
      let(:status_page_url) { 'https://status.gitlab.com/#' }

      it { is_expected.to eq(expected_url) }
    end

    context 'when status_page_url matches expected url' do
      let(:status_page_url) { 'https://status.gitlab.com/#/' }

      it { is_expected.to eq(expected_url) }
    end
  end

  describe '#storage_client' do
    let(:status_page_setting) { build(:status_page_setting, :enabled) }

    before do
      allow(status_page_setting)
        .to receive(:enabled?).and_return(status_page_setting_enabled)
    end

    subject { status_page_setting.storage_client }

    context 'when status page settings is enabled' do
      let(:status_page_setting_enabled) { true }

      it { is_expected.to be_instance_of(Gitlab::StatusPage::Storage::S3Client) }
    end

    context 'when not enabled' do
      let(:status_page_setting_enabled) { false }

      it { is_expected.to be_nil }
    end
  end
end
