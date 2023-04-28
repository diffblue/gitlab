# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/_page', feature_category: :global_search do
  let_it_be(:user) { build_stubbed(:user) }

  describe 'EE tanuki_bot_chat' do
    before do
      allow(view).to receive(:show_super_sidebar?).and_return(true)
      allow(view).to receive(:current_user).and_return(user)
      allow(view).to receive(:current_user_mode).and_return(Gitlab::Auth::CurrentUserMode.new(user))
    end

    describe 'when ::Gitlab::Llm::TanukiBot.enabled_for? is true' do
      before do
        allow(::Gitlab::Llm::TanukiBot).to receive(:enabled_for?).with(user: user).and_return(true)
      end

      it 'renders #js-tanuki-bot-chat-app' do
        render

        expect(rendered).to have_selector('#js-tanuki-bot-chat-app')
      end
    end

    describe 'when ::Gitlab::Llm::TanukiBot.enabled_for? is false' do
      before do
        allow(::Gitlab::Llm::TanukiBot).to receive(:enabled_for?).with(user: user).and_return(false)
      end

      it 'does not render #js-tanuki-bot-chat-app' do
        render

        expect(rendered).not_to have_selector('#js-tanuki-bot-chat-app')
      end
    end
  end
end
