# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sitemap::CreateService, feature_category: :pages do
  describe '#execute' do
    subject { described_class.new.execute }

    it 'returns the successful service response with the sitemap content' do
      sitemap_file = Gitlab::Sitemaps::SitemapFile.new

      allow(sitemap_file).to receive(:render).and_return('foo')
      allow(Gitlab::Sitemaps::Generator).to receive(:execute).and_return(sitemap_file)

      expect(subject).to be_success
      expect(subject.payload[:sitemap]).to eq 'foo'
    end

    context 'when the sitemap generator returns an error' do
      it 'returns an error service response' do
        allow(Gitlab).to receive(:com?).and_return(false)

        expect(subject).to be_error
        expect(subject.message).to eq 'The sitemap can only be generated for Gitlab.com'
      end
    end
  end
end
