# frozen_string_literal: true

RSpec.shared_examples 'includes CustomHttpExternallyDestinationable concern' do
  describe 'validations' do
    it { is_expected.to be_a(AuditEvents::CustomHttpExternallyDestinationable) }

    it { is_expected.to validate_length_of(:destination_url).is_at_most(255) }
    it { is_expected.to validate_presence_of(:destination_url) }
    it { is_expected.to validate_length_of(:verification_token).is_at_least(16).is_at_most(24) }

    it { is_expected.to validate_length_of(:name).is_at_most(72) }

    context 'when creating without a name' do
      before do
        allow(SecureRandom).to receive(:uuid).and_return('12345678')
      end

      it 'assigns a default name' do
        destination = build(:external_audit_event_destination, name: nil)
        destination.valid?

        expect(destination.name).to eq('Destination_12345678')
      end
    end

    context 'when creating with undefined verification token' do
      it 'destination is valid' do
        expect(destination_without_verification_token).to be_valid
      end

      it 'verification token is present' do
        expect(destination_without_verification_token.verification_token).to be_present
      end
    end

    context 'when updating' do
      before do
        destination.save!
      end

      it 'verification token cannot be nil' do
        destination.verification_token = nil

        expect(destination).not_to be_valid
      end
    end
  end

  describe '#allowed_to_stream?' do
    using RSpec::Parameterized::TableSyntax

    where(:destination_object, :audit_operation_val, :result) do
      ref(:destination_with_filters_of_given_type) | ref(:audit_operation) | true
      ref(:destination_with_filters)               | ref(:audit_operation) | false
      ref(:destination)                            | ref(:audit_operation) | true
      ref(:destination_with_filters_of_given_type) | nil                   | true
    end

    with_them do
      it { expect(destination_object.allowed_to_stream?(audit_operation_val)).to eq(result) }
    end
  end
end
