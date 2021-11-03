# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::HookData::GroupMemberBuilder do
  let(:group_member) { create(:group_member, :developer, group: group) }

  describe '#build' do
    let(:event) { :create }
    let(:data) { described_class.new(group_member).build(event) }

    context 'data' do
      context 'group_plan attribute', :saas do
        let(:group) { create(:group_with_plan, plan: :ultimate_plan) }

        it 'returns correct group_plan' do
          expect(data).to include(:group_plan)
          expect(data[:group_plan]).to eq('ultimate')
        end
      end
    end
  end
end
