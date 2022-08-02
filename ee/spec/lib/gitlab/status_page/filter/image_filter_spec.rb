# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::StatusPage::Filter::ImageFilter do
  include FilterSpecHelper

  describe '.call' do
    subject { filter(original_html, context_options) }

    let(:issue_iid) { 1 }
    let(:secret) { '50b7a196557cf72a98e86a7ab4b1ac3b' }
    let(:filename) { 'tanuki.png' }
    let(:original_source_path) { "/uploads/#{secret}/#{filename}" }
    let(:expected_source_path) { Gitlab::StatusPage::Storage.upload_path(issue_iid, secret, filename) }
    let(:original_html) { %Q{<a class="no-attachment-icon gfm" href="#{original_source_path}" target="_blank" rel="noopener noreferrer"><img class="lazy" data-src="#{original_source_path}"></a>} }
    let(:context_options) { { post_process_pipeline: Gitlab::StatusPage::Pipeline::PostProcessPipeline, issue_iid: issue_iid } }
    let(:img_tag) { Nokogiri::HTML(subject).css('img')[0] }
    let(:link_tag) { img_tag.parent }

    it { expect(img_tag['src']).to eq(expected_source_path) }
    it { expect(img_tag['class']).to eq('gl-image') }
    it { expect(link_tag['href']).to eq(expected_source_path) }

    context 'when no issue_iid key' do
      let(:context_options) { { post_process_pipeline: Gitlab::StatusPage::Pipeline::PostProcessPipeline } }

      it 'raises error' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'when issue_iid is nil' do
      let(:issue_iid) { nil }

      it 'raises error' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'no image tags in original html' do
      let(:original_html) { %{<a href="hello/world"></a>} }

      it { is_expected.to eq(original_html) }
    end
  end
end
