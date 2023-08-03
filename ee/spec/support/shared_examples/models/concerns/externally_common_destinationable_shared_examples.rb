# frozen_string_literal: true

RSpec.shared_examples 'includes ExternallyCommonDestinationable concern' do
  describe 'validations' do
    it { is_expected.to be_a(AuditEvents::ExternallyCommonDestinationable) }
    it { is_expected.to validate_length_of(:name).is_at_most(72) }

    context 'when creating without a name' do
      before do
        allow(SecureRandom).to receive(:uuid).and_return('12345678')
      end

      it 'assigns a default name' do
        destination = build(model_factory_name, name: nil)
        destination.valid?

        expect(destination.name).to eq('Destination_12345678')
      end
    end
  end
end
