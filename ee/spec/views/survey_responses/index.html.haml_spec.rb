# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'survey_responses/index' do
  describe 'response page' do
    it 'shows a friendly message' do
      render

      expect(rendered).to have_content(_('Thank you for your feedback!'))
      expect(rendered).to have_content(_('Your response has been recorded.'))

      expect(rendered).not_to have_content(_('Have more to say about GitLab?'))
      expect(rendered).not_to have_content(_('Have a quick chat with us about your experience.'))
      expect(rendered).not_to have_content(_('Receive a $50 gift card as a thank you for your time.'))
      expect(rendered).not_to have_link(_("Let's talk!"))
    end

    context 'when invite_link instance variable is set' do
      before do
        assign(:invite_link, SurveyResponsesController::CALENDLY_INVITE_LINK)
      end

      it 'shows invitation text and link' do
        render

        expect(rendered).to have_content(_('Have more to say about GitLab?'))
        expect(rendered).to have_content(_('Have a quick chat with us about your experience.'))
        expect(rendered).to have_link(_("Let's talk!"), href: SurveyResponsesController::CALENDLY_INVITE_LINK)
        expect(rendered).not_to have_content(_('Receive a $50 gift card as a thank you for your time.'))
      end

      context 'when @show_incentive is true' do
        before do
          assign(:show_incentive, true)
        end

        it 'shows text about the incentive' do
          render

          expect(rendered).to have_content(_('Have more to say about GitLab?'))
          expect(rendered).to have_content(_('Have a quick chat with us about your experience.'))
          expect(rendered).to have_content(_('Receive a $50 gift card as a thank you for your time.'))
          expect(rendered).to have_link(_("Let's talk!"), href: SurveyResponsesController::CALENDLY_INVITE_LINK)
        end
      end
    end
  end
end
