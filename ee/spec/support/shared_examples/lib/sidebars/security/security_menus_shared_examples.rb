# frozen_string_literal: true

RSpec.shared_examples 'Security menu' do |link:, title:, icon:, active_route:|
  let_it_be(:user) { create(:user) }

  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

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

  it 'renders if user is logged in' do
    expect(subject.render?).to be true
  end

  context 'when user is not logged in' do
    it 'does not render' do
      expect(described_class.new(Sidebars::Context.new(current_user: nil, container: nil)).render?).to be false
    end
  end
end
