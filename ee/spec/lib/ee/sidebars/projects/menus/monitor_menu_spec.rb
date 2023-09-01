# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::MonitorMenu do
  let(:project) { build(:project) }
  let(:user) { project.first_owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project, show_cluster_hint: true) }

  describe 'Menu items' do
    subject { described_class.new(context).renderable_items.index { |e| e.item_id == item_id } }

    describe 'On-call Schedules' do
      let(:item_id) { :on_call_schedules }

      before do
        stub_licensed_features(oncall_schedules: true)
      end

      specify { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end
    end

    describe 'Escalation Policies' do
      let(:item_id) { :escalation_policies }

      before do
        stub_licensed_features(oncall_schedules: true, escalation_policies: true)
      end

      specify { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end
    end

    describe 'Tracing' do
      let(:item_id) { :tracing }

      before do
        allow(Gitlab::Observability).to receive(:tracing_enabled?).and_return(true)
      end

      specify { is_expected.not_to be_nil }

      describe 'when feature is disabled' do
        before do
          allow(Gitlab::Observability).to receive(:tracing_enabled?).and_return(false)
        end

        specify { is_expected.to be_nil }
      end
    end
  end
end
