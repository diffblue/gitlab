# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuableMetricImage do
  subject { build(:issuable_metric_image) }

  describe 'associations' do
    it { is_expected.to belong_to(:issue) }
  end

  describe 'validation' do
    let(:txt_file) { fixture_file_upload('spec/fixtures/doc_sample.txt', 'text/plain') }
    let(:img_file) { fixture_file_upload('spec/fixtures/rails_sample.jpg', 'image/jpg') }

    it { is_expected.not_to allow_value(txt_file).for(:file) }
    it { is_expected.to allow_value(img_file).for(:file) }
    it { is_expected.to validate_length_of(:url_text).is_at_most(128) }

    describe 'url' do
      it { is_expected.not_to allow_value('test').for(:url) }
      it { is_expected.not_to allow_value('www.gitlab.com').for(:url) }
      it { is_expected.to allow_value('').for(:url) }
      it { is_expected.to allow_value('http://www.gitlab.com').for(:url) }
      it { is_expected.to allow_value('https://www.gitlab.com').for(:url) }
    end
  end

  describe 'scopes' do
    let_it_be(:issue) { create(:issue) }
    let_it_be(:image_1) { create(:issuable_metric_image, issue: issue) }
    let_it_be(:image_2) { create(:issuable_metric_image, issue: issue) }

    describe '.order_created_at_asc' do
      subject { described_class.order_created_at_asc }

      it 'orders in ascending order' do
        expect(subject).to eq([image_1, image_2])
      end
    end
  end

  describe '.available_for?' do
    subject { IssuableMetricImage.available_for?(issue.project) }

    before do
      stub_licensed_features(incident_metric_upload: true)
    end

    let_it_be_with_refind(:issue) { create(:issue) }

    context 'license enabled' do
      it { is_expected.to eq(true) }
    end

    context 'license disabled' do
      before do
        stub_licensed_features(incident_metric_upload: false)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '#file_path' do
    let(:issuable_metric_image) { create(:issuable_metric_image) }
    let(:expected_path) { issuable_metric_image.file.url }

    subject(:file_path) { issuable_metric_image.file_path }

    context 'with asset host configured' do
      it 'returns a full URL with the asset host and system path' do
        asset_host = 'https://gitlab-assets.example.com'
        allow(ActionController::Base).to receive(:asset_host) { asset_host }

        expect(file_path).to eq("#{asset_host}#{expected_path}")
      end
    end

    context 'no asset path configured' do
      it 'returns a full URL with the base url and system path' do
        base_url = Gitlab.config.gitlab.base_url
        expect(file_path).to eq("#{base_url}#{expected_path}")
      end
    end
  end
end
