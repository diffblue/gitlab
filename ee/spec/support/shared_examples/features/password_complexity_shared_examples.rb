# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'password complexity validations' do
  context 'when password complexity feature is not available' do
    before do
      stub_licensed_features(password_complexity: false)
      stub_application_setting(password_number_required: true)
    end

    context 'when no rule is required' do
      before do
        visit path_to_visit
      end

      it 'does not render any rule' do
        expect(page).not_to have_selector('[data-testid="password-rule-text"]')
      end
    end
  end

  context 'when password complexity feature is available' do
    before do
      stub_licensed_features(password_complexity: true)
    end

    context 'when no rule is required' do
      before do
        visit path_to_visit
      end

      it 'does not render any rule' do
        expect(page).not_to have_selector('[data-testid="password-rule-text"]')
      end
    end

    context 'when two rules are required ' do
      before do
        stub_application_setting(password_number_required: true)
        stub_application_setting(password_lowercase_required: true)

        visit path_to_visit
      end

      it 'shows two rules' do
        expect(page).to have_selector(
          '[data-testid="password-number-status-icon"].gl-visibility-hidden',
          visible: false, count: 1
        )
        expect(page).to have_selector(
          '[data-testid="password-lowercase-status-icon"].gl-visibility-hidden',
          visible: false, count: 1
        )
        expect(page).to have_selector('[data-testid="password-rule-text"]', count: 2)
      end
    end

    context 'when all passsword rules are required' do
      include_context 'with all password complexity rules enabled'

      before do
        visit path_to_visit
        fill_in password_input_selector, with: password
      end

      context 'password does not meet all rules' do
        context 'when password does not have a number' do
          let(:password) { 'aA!' }

          it 'does not show check circle' do
            expect(page).to have_selector('[data-testid="password-number-status-icon"].gl-visibility-hidden',
              visible: false, count: 1)
          end
        end
      end

      context 'when clicking on submit button' do
        context 'when password rules are not fully matched' do
          let(:password) { 'aA' }

          it 'highlights not matched rules' do
            expect(page).to have_selector('[data-testid="password-rule-text"].gl-text-red-500', count: 0)

            click_button submit_button_selector

            expect(page).to have_selector('[data-testid="password-rule-text"].gl-text-red-500', count: 2)
          end
        end
      end
    end
  end
end
