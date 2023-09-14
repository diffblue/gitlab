# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::AmazonS3Configuration, feature_category: :audit_events do
  describe 'validations' do
    let_it_be(:group) { create(:group) }
    let_it_be(:s3_configuration) { create(:amazon_s3_configuration, group: group) }

    it { is_expected.to validate_uniqueness_of(:name).scoped_to([:namespace_id]) }
    it { is_expected.to validate_uniqueness_of(:bucket_name).scoped_to([:namespace_id]) }
    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:access_key_xid) }
    it { is_expected.to validate_presence_of(:bucket_name) }
    it { is_expected.to validate_presence_of(:aws_region) }
    it { is_expected.to validate_presence_of(:secret_access_key) }

    describe 'namespace_is_group' do
      let(:s3_configuration) { build(:amazon_s3_configuration, group: group) }

      context 'when namespace is a group' do
        let_it_be(:group) { create(:group) }

        it 'is valid' do
          expect(s3_configuration).to be_valid
        end
      end

      context 'when namespace is a subgroup' do
        let_it_be(:group) { create(:group, :nested) }

        it 'is not valid' do
          expect(s3_configuration).not_to be_valid
        end
      end
    end
  end

  describe 'Associations' do
    it 'belongs to a group' do
      is_expected.to belong_to(:group).with_foreign_key(:namespace_id).inverse_of(:amazon_s3_configurations)
    end
  end

  it_behaves_like 'includes Limitable concern' do
    subject { build(:amazon_s3_configuration, group: create(:group)) }
  end

  it_behaves_like 'includes ExternallyCommonDestinationable concern' do
    let(:model_factory_name) { :amazon_s3_configuration }
  end
end
