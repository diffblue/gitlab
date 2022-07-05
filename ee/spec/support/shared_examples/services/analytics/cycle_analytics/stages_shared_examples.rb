# frozen_string_literal: true

RSpec.shared_examples 'permission check for Value Stream Analytics Stage services' do |required_license|
  context 'when user has no access' do
    before do
      group.add_member(user, :guest)
    end

    it { expect(subject).to be_error }
    it { expect(subject.http_status).to eq(:forbidden) }
  end

  context 'when license is missing' do
    before do
      stub_licensed_features(required_license => false)
    end

    it { expect(subject).to be_error }
    it { expect(subject.http_status).to eq(:forbidden) }
  end
end
