# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Training, feature_category: :vulnerability_management do
  describe 'associations' do
    it { is_expected.to belong_to(:project).required }
    it { is_expected.to belong_to(:provider).required }
  end

  describe 'validations' do
    describe 'one primary per project' do
      context 'when the training is primary' do
        subject { create(:security_training, :primary) }

        it { is_expected.to validate_uniqueness_of(:is_primary).scoped_to(:project_id) }
      end

      context 'when the training is not primary' do
        subject { create(:security_training) }

        it { is_expected.not_to validate_uniqueness_of(:is_primary) }
      end
    end

    it { is_expected.not_to allow_value(nil).for(:is_primary) }
  end

  describe '.not_including scope' do
    let_it_be(:training1) { create(:security_training) }
    let_it_be(:training2) { create(:security_training) }

    subject { described_class.not_including(training1) }

    it { is_expected.to contain_exactly(training2) }
  end

  describe 'deleting a record' do
    subject { training.destroy } # rubocop:disable Rails/SaveBang

    context 'when the record is not primary' do
      let(:training) { create(:security_training) }

      it { is_expected.to be_truthy }
    end

    context 'when the record is primary' do
      let(:training) { create(:security_training, :primary) }

      context 'when there is no other training enabled for the project' do
        it { is_expected.to be_truthy }
      end

      context 'when there is another training enabled for the project' do
        before do
          create(:security_training, project: training.project)
        end

        it { is_expected.to be_falsey }

        it "adds an error" do
          subject

          expect(training.errors.messages[:base].first).to eq('Can not delete primary training')
        end
      end
    end
  end
end
