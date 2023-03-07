# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::WikiMenu, feature_category: :navigation do
  let_it_be(:owner) { create(:user) }
  let_it_be_with_refind(:group) do
    build(:group, :private).tap do |g|
      g.add_owner(owner)
    end
  end

  let(:user) { owner }
  let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }
  let(:menu) { described_class.new(context) }

  describe '#render?' do
    let(:wiki_enabled) { true }

    subject { menu.render? }

    before do
      stub_licensed_features(group_wikis: wiki_enabled)
    end

    context 'when user can access group wiki' do
      specify { is_expected.to be true }

      context 'when feature is not enabled' do
        let(:wiki_enabled) { false }

        specify { is_expected.to be false }
      end
    end

    context 'when user cannot access group wiki' do
      let(:user) { nil }

      specify { is_expected.to be false }
    end
  end

  it_behaves_like 'serializable as super_sidebar_menu_args' do
    let(:extra_attrs) do
      {
        super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::PlanMenu,
        item_id: :group_wiki
      }
    end
  end
end
