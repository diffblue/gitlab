# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::IssuesMenu do
  let_it_be(:owner) { create(:user) }

  let(:group) do
    build(:group, :private).tap do |g|
      g.add_owner(owner)
    end
  end

  let(:user) { owner }
  let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }

  describe 'Menu Items' do
    subject { described_class.new(context).renderable_items.find { |e| e.item_id == item_id } }

    describe 'Iterations' do
      let(:item_id) { :iterations }
      let(:iterations_enabled) { true }

      before do
        stub_licensed_features(iterations: iterations_enabled)
      end

      context 'when licensed feature iterations is not enabled' do
        let(:iterations_enabled) { false }

        it 'does not include iterations menu item' do
          is_expected.to be_nil
        end
      end

      context 'when licensed feature iterations is enabled' do
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

      it 'contains the iteration cadences link' do
        expect(subject.link).to include "/groups/#{group.full_path}/-/cadences"
      end

      it 'includes iteration and iteration_cadences active routes' do
        expect(subject.active_routes[:path]).to contain_exactly('iterations#index', 'iterations#show', 'iterations#new', 'iteration_cadences#index')
      end
    end
  end
end
