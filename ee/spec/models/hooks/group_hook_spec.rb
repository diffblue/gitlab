# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupHook do
  describe 'associations' do
    it { is_expected.to belong_to :group }
  end

  it_behaves_like 'includes Limitable concern' do
    subject { build(:group_hook) }
  end

  describe '#parent' do
    it 'returns the associated group' do
      group = build(:group)
      hook = build(:group_hook, group: group)

      expect(hook.parent).to eq(group)
    end
  end

  describe '#application_context' do
    let_it_be(:hook) { build(:group_hook) }

    it 'includes the type and group' do
      expect(hook.application_context).to eq(
        related_class: 'GroupHook',
        namespace: hook.group
      )
    end
  end
end
