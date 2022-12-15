# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupHook do
  describe 'associations' do
    it { is_expected.to belong_to :group }
  end

  it_behaves_like 'includes Limitable concern' do
    subject { build(:group_hook) }
  end

  describe 'executable?' do
    let!(:hooks) do
      [
        [0, Time.current],
        [0, 1.minute.from_now],
        [1, 1.minute.from_now],
        [3, 1.minute.from_now],
        [4, nil],
        [4, 1.day.ago],
        [4, 1.minute.from_now],
        [0, nil],
        [0, 1.day.ago],
        [1, nil],
        [1, 1.day.ago],
        [3, nil],
        [3, 1.day.ago]
      ].map do |(recent_failures, disabled_until)|
        create(:service_hook, recent_failures: recent_failures, disabled_until: disabled_until)
      end
    end

    it 'is always true' do
      expect(hooks).to all(be_executable)
    end
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
