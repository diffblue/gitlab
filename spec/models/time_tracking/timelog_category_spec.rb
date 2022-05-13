# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TimeTracking::TimelogCategory, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:group).with_foreign_key('group_id') }
  end

  describe 'validations' do
    subject { create(:timelog_category) }

    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive.scoped_to([:group_id]) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(1024) }
    it { is_expected.to validate_length_of(:color).is_at_most(7) }
  end

  describe 'validations when billable' do
    subject { create(:timelog_category, billable: true, billing_rate: 10.5) }

    it { is_expected.to validate_presence_of(:billing_rate) }
    it { is_expected.to validate_numericality_of(:billing_rate).is_greater_than(0) }
  end

  describe '#name' do
    it 'strips name' do
      timelog_category = described_class.new(name: '  TimelogCategoryTest  ')
      timelog_category.valid?

      expect(timelog_category.name).to eq('TimelogCategoryTest')
    end
  end

  describe '#color' do
    it 'strips color' do
      timelog_category = described_class.new(name: 'TimelogCategoryTest', color: '  #fafafa  ')
      timelog_category.valid?

      expect(timelog_category.color).to eq(::Gitlab::Color.of('#fafafa'))
    end
  end

  describe '#find_by_name' do
    let_it_be(:group_a) { create(:group) }
    let_it_be(:group_b) { create(:group) }
    let_it_be(:timelog_category_a) { create(:timelog_category, group: group_a, name: 'TimelogCategoryTest') }

    it 'finds the correct timelog category' do
      expect(described_class.find_by_name(group_a.id, 'TIMELOGCATEGORYTest')).to match_array([timelog_category_a])
    end

    it 'returns empty if not found' do
      expect(described_class.find_by_name(group_b.id, 'TIMELOGCATEGORYTest')).to be_empty
    end
  end
end
