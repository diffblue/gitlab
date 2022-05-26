# frozen_string_literal: true

RSpec.shared_examples 'dast url addressable' do
  it 'includes UrlAddressable' do
    expect(described_class).to include(AppSec::Dast::UrlAddressable)
  end

  context 'when the url is not public' do
    before do
      subject.url = 'http://127.0.0.1'
    end

    it 'is valid', :aggregate_failures do
      expect(subject).to be_valid
    end
  end
end
