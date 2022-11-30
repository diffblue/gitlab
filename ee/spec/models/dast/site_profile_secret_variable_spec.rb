# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dast::SiteProfileSecretVariable, type: :model do
  let_it_be(:dast_site_profile) { create(:dast_site_profile) }

  subject { create(:dast_site_profile_secret_variable, dast_site_profile: dast_site_profile) }

  it_behaves_like 'CI variable'

  describe 'associations' do
    it { is_expected.to belong_to(:dast_site_profile) }
  end

  describe 'validations' do
    it { is_expected.to be_valid }
    it { is_expected.to include_module(Ci::Maskable) }
    it { is_expected.to include_module(Ci::HasVariable) }
    it { is_expected.to validate_presence_of(:dast_site_profile_id) }
    it { is_expected.to validate_inclusion_of(:masked).in_array([true]) }
    it { is_expected.to validate_uniqueness_of(:key).scoped_to(:dast_site_profile_id).with_message(/\(\w+\) has already been taken/) }

    it 'only allows records where variable_type=env_var', :aggregate_failures do
      subject = build(:dast_site_profile_secret_variable, variable_type: :file)

      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to include('Variable type is not included in the list')
    end

    describe '#value' do
      subject { build(:dast_site_profile_secret_variable, dast_site_profile: dast_site_profile, raw_value: raw_value) }

      context 'when the value is over the limit' do
        let(:raw_value) { SecureRandom.alphanumeric(10_003) }

        it 'is not valid', :aggregate_failures do
          expect(subject).not_to be_valid
          expect(subject.errors.full_messages).to include('Value exceeds 10000 characters')
        end

        it 'raises a database level error' do
          allow(subject).to receive(:valid?).and_return(true)

          expect { subject.save! }.to raise_error(ActiveRecord::StatementInvalid)
        end
      end

      context 'when value at the maximum value' do
        let(:raw_value) { SecureRandom.alphanumeric(10_000) }

        it 'is valid' do
          expect(subject).to be_valid
        end

        it 'does not raise database level error' do
          allow(subject).to receive(:valid?).and_return(true)

          expect { subject.save! }.not_to raise_error
        end
      end

      context 'when value at the minimum value' do
        let(:raw_value) { SecureRandom.alphanumeric(8) }

        it 'is valid' do
          expect(subject).to be_valid
        end

        it 'does not raise database level error' do
          allow(subject).to receive(:valid?).and_return(true)

          expect { subject.save! }.not_to raise_error
        end
      end

      context 'when value is under the limit' do
        let(:raw_value) { SecureRandom.alphanumeric(7) }

        it 'is not valid', :aggregate_failures do
          expect(subject).not_to be_valid
          expect(subject.errors.full_messages).to include('Value is less than 8 characters')
        end
      end
    end
  end

  describe '#masked' do
    it 'defaults to true', :aggregate_failures do
      expect(subject.masked).to eq(true)
      expect(described_class.new.masked).to eq(true)
    end
  end

  describe '#project' do
    it 'delegates to dast_site_profile' do
      expect(subject.project).to eq(subject.dast_site_profile.project)
    end
  end

  describe '#raw_value=' do
    it 'pre-encodes the value' do
      value = SecureRandom.alphanumeric

      subject = create(:dast_site_profile_secret_variable, raw_value: value)

      expect(Base64.strict_decode64(subject.value)).to eq(value)
    end
  end

  describe '#value=' do
    it 'raises an error because #raw_value= should be used instead' do
      expect { subject.value = SecureRandom.alphanumeric }.to raise_error(NoMethodError, /private method `value=' called for/)
    end
  end

  describe '#variable_type' do
    it 'defaults to env_var', :aggregate_failures do
      variable_type = 'env_var'

      expect(subject.variable_type).to eq(variable_type)
      expect(described_class.new.variable_type).to eq(variable_type)
    end
  end
end
