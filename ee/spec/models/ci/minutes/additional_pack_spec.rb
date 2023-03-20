# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Minutes::AdditionalPack, type: :model, feature_category: :continuous_integration do
  describe 'associations' do
    it { is_expected.to belong_to(:namespace) }
  end

  describe 'validations' do
    subject(:additional_pack) { create(:ci_minutes_additional_pack) }

    it { is_expected.to validate_presence_of(:namespace) }
    it { is_expected.to validate_presence_of(:number_of_minutes) }
    it { is_expected.to validate_length_of(:purchase_xid).is_at_most(50) }

    context 'when GitLab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it { is_expected.to validate_presence_of(:expires_at) }
      it { is_expected.to validate_presence_of(:purchase_xid) }
      it { is_expected.to validate_uniqueness_of(:purchase_xid) }
    end

    context 'when self-managed' do
      before do
        allow(Gitlab).to receive(:com?).and_return(false)
      end

      it { is_expected.not_to validate_presence_of(:purchase_xid) }
      it { is_expected.not_to validate_presence_of(:expires_at) }
      it { is_expected.not_to validate_uniqueness_of(:purchase_xid) }
    end
  end

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:model) { create(:ci_minutes_additional_pack) }

    let!(:parent) { model.namespace }
  end
end
