# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/application' do
  let_it_be(:user) { create(:user) }

  before do
    allow(view).to receive(:session).and_return({})
    allow(view).to receive(:user_signed_in?).and_return(true)
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:current_user_mode).and_return(Gitlab::Auth::CurrentUserMode.new(user))
  end

  it_behaves_like 'a layout which reflects the application theme setting'

  describe 'layouts/_user_notification_dot' do
    let(:track_selector) { '[data-track-action="render"][data-track-label="show_buy_ci_minutes_notification"]' }
    let(:show_notification_dot) { false }

    before do
      allow(view).to receive(:show_pipeline_minutes_notification_dot?).and_return(show_notification_dot)
    end

    context 'when we show the notification dot' do
      let(:show_notification_dot) { true }

      before do
        allow(Gitlab).to receive(:com?) { true }
      end

      it 'has the notification dot' do
        render

        expect(rendered).to have_css('li', class: 'header-user') do
          expect(rendered).to have_css("span#{track_selector}", class: 'notification-dot')
        end
      end
    end

    context 'when we do not show the notification dot' do
      it 'does not have the notification dot' do
        render

        expect(rendered).to have_css('li', class: 'header-user') do
          expect(rendered).not_to have_css("span#{track_selector}", class: 'notification-dot')
        end
      end
    end
  end
end
