# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::ReturnToLocation do
  describe '#full_path' do
    it 'returns nil when location nil' do
      subject = described_class.new(nil)

      expect(subject.full_path).to be_nil
    end

    it 'returns an empty string when location is empty' do
      subject = described_class.new('')

      expect(subject.full_path).to eq ''
    end

    it 'removes the domain from location' do
      subject = described_class.new('http://example.com/foo/bar')

      expect(subject.full_path).to eq '/foo/bar'
    end

    it 'keeps the query string from location' do
      subject = described_class.new('http://example.com/foo/bar?a=1&b=2')

      expect(subject.full_path).to eq '/foo/bar?a=1&b=2'
    end

    it 'keeps the fragments from location' do
      subject = described_class.new('http://example.com/foo/bar#section')

      expect(subject.full_path).to eq '/foo/bar#section'
    end
  end
end
