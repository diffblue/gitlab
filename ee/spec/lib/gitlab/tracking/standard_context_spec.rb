# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::StandardContext do
  let_it_be(:project) { create(:project) }
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:plan) { :ultimate_plan }

  let(:snowplow_context) { subject.to_context }

  describe '#to_context' do
    context 'plan' do
      context 'when namespace is not available' do
        it 'is nil' do
          expect(snowplow_context.to_json.dig(:data, :plan)).to be_nil
        end
      end

      context 'when namespace is available', :saas do
        let(:namespace) { create(:namespace_with_plan, plan: plan) }

        subject { described_class.new(namespace_id: namespace.id, plan_name: namespace.actual_plan_name) }

        it 'contains plan name' do
          expect(snowplow_context.to_json.dig(:data, :plan)).to eq(Plan::ULTIMATE)
        end
      end
    end
  end
end
