# frozen_string_literal: true

# 2 Required let variables that should be valid, unpersisted instances of the same
# model class. Or valid, persisted instances of the same model class in a not-yet
# loaded let variable (so we can trigger creation):
#
# - verifiable_model_record: should be such that it will be included in the scope
#                            available_verifiables
# - unverifiable_model_record: should be such that it will not be included in
#                              the scope available_verifiables

RSpec.shared_examples 'a replicable model with a separate table for verification state' do
  include EE::GeoHelpers

  describe '.with_verification_state' do
    let(:verification_model_class) { verifiable_model_record.class }

    it 'returns records with given scope' do
      expect(verification_model_class.with_verification_state(:verification_succeeded).size).to eq(0)

      verifiable_model_record.verification_failed_with_message!('Test')

      expect(verification_model_class.with_verification_state(:verification_failed).first).to eq verifiable_model_record
    end
  end

  describe '.checksummed' do
    let(:verification_model_class) { verifiable_model_record.class }

    it 'returns records with given scope' do
      expect(verification_model_class.checksummed.size).to eq(0)

      verifiable_model_record.verification_started!
      verifiable_model_record.verification_succeeded_with_checksum!('checksum', Time.now)

      expect(verification_model_class.checksummed.first).to eq verifiable_model_record
    end
  end

  describe '.not_checksummed' do
    let(:verification_model_class) { verifiable_model_record.class }

    it 'returns records with given scope' do
      verifiable_model_record.verification_started!
      verifiable_model_record.verification_failed_with_message!('checksum error')

      expect(verification_model_class.not_checksummed.first).to eq verifiable_model_record

      verifiable_model_record.verification_started!
      verifiable_model_record.verification_succeeded_with_checksum!('checksum', Time.now)

      expect(verification_model_class.not_checksummed.size).to eq(0)
    end
  end

  describe '#save_verification_details' do
    let(:verifiable_model_class) { verifiable_model_record.class }
    let(:verification_state_table_class) { verifiable_model_class.verification_state_table_class }
    let(:replicator_class) { verifiable_model_class.replicator_class }

    context 'when model record is not part of verifiables scope' do
      before do
        next unless unverifiable_model_record.nil?

        skip "Skipping because all #{replicator_class.replicable_title_plural} are records that can be checksummed"
      end

      it 'does not create verification details' do
        expect { unverifiable_model_record.save! }.not_to change { verification_state_table_class.count }
      end
    end

    context 'when model_record is part of verifiables scope' do
      it 'creates verification details' do
        expect { verifiable_model_record.save! }.to change { verification_state_table_class.count }.by(1)
      end
    end
  end
end
