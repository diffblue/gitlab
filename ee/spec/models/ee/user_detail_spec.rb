# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserDetail, feature_category: :system_access do
  it { is_expected.to belong_to(:provisioned_by_group) }
  it { is_expected.to belong_to(:enterprise_group) }

  describe '#provisioned_by_group?' do
    let(:user) { create(:user, provisioned_by_group: build(:group)) }

    subject { user.user_detail.provisioned_by_group? }

    it 'returns true when user is provisioned by group' do
      expect(subject).to eq(true)
    end

    it 'returns true when user is provisioned by group' do
      user.user_detail.update!(provisioned_by_group: nil)

      expect(subject).to eq(false)
    end
  end

  context 'with loose foreign key on user_details.provisioned_by_group_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:group) }
      let!(:model) { create(:user_detail, provisioned_by_group: parent) }
    end
  end

  context 'with loose foreign key on user_details.enterprise_group_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:group) }
      let!(:model) { create(:user_detail, enterprise_group: parent) }
    end
  end
end
