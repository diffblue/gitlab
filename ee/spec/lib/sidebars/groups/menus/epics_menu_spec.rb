# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::EpicsMenu, feature_category: :navigation do
  let_it_be(:owner) { create(:user) }
  let_it_be(:group) do
    build(:group, :private).tap do |g|
      g.add_owner(owner)
    end
  end

  let(:user) { owner }
  let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }
  let(:menu) { described_class.new(context) }

  describe 'Menu Items' do
    subject { menu.renderable_items }

    before do
      stub_licensed_features(epics: true)
    end

    describe 'when the user has access to epics' do
      it 'has all the menus' do
        expect(subject.map(&:item_id)).to include(:epic_list, :boards, :roadmap)
      end
    end

    describe 'when the user does not have access' do
      let(:user) { nil }

      specify { is_expected.to be_empty }
    end
  end

  it_behaves_like 'pill_count formatted results' do
    let(:count_service) { ::Groups::EpicsCountService }
  end

  it_behaves_like 'serializable as super_sidebar_menu_args' do
    let(:extra_attrs) do
      {
        item_id: :group_epic_list,
        pill_count: menu.pill_count,
        has_pill: menu.has_pill?,
        super_sidebar_parent: Sidebars::Groups::SuperSidebarMenus::PlanMenu
      }
    end
  end
end
