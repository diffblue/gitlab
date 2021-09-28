# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::IssuesMenu do
  let(:project) { build(:project) }
  let(:user) { project.owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }

  describe 'Iterations' do
    subject { described_class.new(context).renderable_items.index { |e| e.item_id == :iterations} }

    context 'when licensed feature iterations is not enabled' do
      it 'does not include iterations menu item' do
        stub_licensed_features(iterations: false)

        is_expected.to be_nil
      end
    end

    context 'when licensed feature iterations is enabled' do
      before do
        stub_licensed_features(iterations: true)
      end

      context 'when user can read iterations' do
        it 'includes iterations menu item' do
          is_expected.to be_present
        end
      end

      context 'when user cannot read iterations' do
        let(:user) { nil }

        it 'does not include iterations menu item' do
          is_expected.to be_nil
        end
      end
    end
  end

  describe 'Requirements' do
    subject { described_class.new(context).renderable_items.any? { |e| e.item_id == :requirements} }

    context 'when licensed feature requirements is not enabled' do
      it 'does not include requirements menu item' do
        stub_licensed_features(requirements: false)

        is_expected.to be_falsy
      end
    end

    context 'when licensed feature requirements is enabled' do
      before do
        stub_licensed_features(requirements: true)
      end

      context 'when user can read requirements' do
        it 'includes requirements menu item' do
          is_expected.to be_truthy
        end
      end

      context 'when user cannot read requirements' do
        let(:user) { nil }

        it 'does not include requirements menu item' do
          is_expected.to be_falsy
        end
      end
    end
  end
end
