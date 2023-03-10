# frozen_string_literal: true

RSpec.shared_examples 'top-level menu item' do |link:, title:, icon:, active_route:, is_super_sidebar: false|
  let_it_be(:user) { build(:user) }

  let(:context) { Sidebars::Context.new(current_user: user, container: nil, is_super_sidebar: is_super_sidebar) }

  subject { described_class.new(context) }

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
    expect(subject.active_routes).to eq active_route
  end
end

RSpec.shared_examples 'top-level menu item with license feature guard' do |access_check: nil|
  let_it_be(:user) { build(:user) }

  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

  subject { described_class.new(context) }

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

  context 'when user is not logged in' do
    before do
      allow(context).to receive(:current_user).and_return(nil)
    end

    it 'does not render' do
      expect(described_class.new(context).render?).to be false
    end
  end
end

RSpec.shared_examples 'top-level menu item with context based feature guard' do |guard:|
  let_it_be(:user) { build(:user) }

  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

  subject { described_class.new(context) }

  context 'when user can access feature' do
    before do
      allow(context).to receive(guard).and_return(true)
    end

    it 'renders' do
      expect(subject.render?).to be true
    end
  end

  context 'when user cannot access feature' do
    before do
      allow(context).to receive(guard).and_return(false)
    end

    it 'does not render' do
      expect(subject.render?).to be false
    end
  end
end

RSpec.shared_examples 'menu without sub menu items' do
  let_it_be(:user) { build(:user) }

  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

  subject { described_class.new(context) }

  it 'does not contain any sub menu' do
    expect(subject.has_items?).to be false
  end
end

RSpec.shared_examples 'top-level menu item with sub menu items' do
  let_it_be(:user) { build(:user) }

  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

  subject { described_class.new(context).instance_variable_get(:@items) }

  it 'matches expected sub menu items' do
    expect(
      subject.map do |item|
        {
          title: item.title,
          link: item.link,
          active_routes: item.active_routes,
          item_id: item.item_id
        }
      end
    ).to eq(sub_menu)
  end

  it 'each sub menu item has a unique item_id' do
    mapped = subject.map(&:item_id)

    expect(mapped).not_to include(nil)
    expect(mapped.length).to eq(subject.length)
    expect(mapped.uniq).to eq(mapped)
  end
end
