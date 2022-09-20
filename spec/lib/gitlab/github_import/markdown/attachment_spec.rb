# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Markdown::Attachment do
  let(:name) { FFaker::Lorem.word }
  let(:url) { FFaker::Internet.uri('https') }

  describe '.from_markdown' do
    let(:markdown) { "[#{name}](#{url})" }

    it 'returns instance with attachment info' do
      attachment = described_class.from_markdown(markdown)

      expect(attachment.name).to eq name
      expect(attachment.url).to eq url
    end
  end

  describe '.from_img_tag' do
    let(:raw_source) { "<img width=\"248\" alt=\"#{name}\" src=\"#{url}\">" }
    let(:tag) { Nokogiri::HTML.parse(raw_source).xpath('//img')[0] }

    it 'returns instance with attachment info' do
      attachment = described_class.from_img_tag(tag)

      expect(attachment.name).to eq name
      expect(attachment.url).to eq url
    end
  end

  describe '#inspect' do
    it 'returns attachment basic info' do
      attachment = described_class.new(name, url)

      expect(attachment.inspect).to eq "Attachment { name: #{name}, url: #{url} }"
    end
  end
end
