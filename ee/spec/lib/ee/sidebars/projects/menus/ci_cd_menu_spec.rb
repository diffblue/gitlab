# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::CiCdMenu do
  let(:project) { build(:project) }
  let(:user) { project.first_owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, current_ref: 'main', container: project, can_view_pipeline_editor: true) }

  describe 'Test cases' do
    subject { described_class.new(context).renderable_items.index { |e| e.item_id == :test_cases } }

    context 'when licensed feature quality_management is not enabled' do
      before do
        stub_licensed_features(quality_management: false)
      end

      it 'does not include test cases menu item' do
        is_expected.to be_nil
      end
    end

    context 'when licensed feature quality_management is enabled' do
      before do
        stub_licensed_features(quality_management: true)
      end

      context 'when user can read issues' do
        it 'includes test cases menu item' do
          is_expected.to be_present
        end
      end

      context 'when user cannot read issues' do
        let(:user) { nil }

        it 'does not include test cases menu item' do
          is_expected.to be_nil
        end
      end
    end
  end
end
