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

  describe '#save_verification_details' do
    let(:verification_state_table_class) { verifiable_model_record.class.verification_state_table_class }

    context 'when model record is not part of available_verifiables scope' do
      it 'does not create verification details' do
        expect { unverifiable_model_record.save! }.not_to change { verification_state_table_class.count }
      end
    end

    context 'when model_record is part of available_verifiables scope' do
      it 'creates verification details' do
        expect { verifiable_model_record.save! }.to change { verification_state_table_class.count }.by(1)
      end
    end
  end
end
