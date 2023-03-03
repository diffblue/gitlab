# frozen_string_literal: true

RSpec.shared_examples 'Top-Level menu item' do |
  link:, title:, icon:, active_route:,
  is_super_sidebar: false, access_check: nil|
  let_it_be(:user) { create(:user) }

  let(:context) { Sidebars::Context.new(current_user: user, container: nil, is_super_sidebar: is_super_sidebar) }

  subject { described_class.new(context) }

  it 'does not contain any sub menu' do
    expect(subject.has_items?).to be false
  end

  it 'renders the correct link' do
    expect(subject.link).to match link
  end

  it 'renders the correct title' do
    expect(subject.title).to be title
  end

  it 'renders the correct icon' do
    expect(subject.sprite_icon).to be icon
  end

  it 'defines correct active route' do
    expect(subject.active_routes[:path]).to be active_route
  end

  context "when feature is unlicensed", if: access_check.nil? do
    it 'renders if user is logged in' do
      expect(subject.render?).to be true
    end
  end

  context "when feature is licensed", if: !access_check.nil? do
    context 'when user can access feature' do
      before do
        allow(Ability).to receive(:allowed?).with(user, access_check).and_return(true)
      end

      it 'renders' do
        expect(subject.render?).to be true
      end
    end

    context 'when user cannot access feature' do
      before do
        allow(Ability).to receive(:allowed?).with(user, access_check).and_return(false)
      end

      it 'does not render' do
        expect(subject.render?).to be false
      end
    end
  end

  context 'when user is not logged in' do
    it 'does not render' do
      context = Sidebars::Context.new(current_user: nil, container: nil, is_super_sidebar: is_super_sidebar)
      expect(described_class.new(context).render?).to be false
    end
  end
end
