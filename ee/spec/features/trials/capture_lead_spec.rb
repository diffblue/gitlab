# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Trial Capture Lead', :js, skip: Gitlab.jh? do
  include Select2Helper
  let(:user) { create(:user) }

  before do
    allow(Gitlab).to receive(:com?).and_return(true).at_least(:once)
    sign_in(user)
  end

  context 'when user' do
    before do
      visit new_trial_path

      wait_for_requests
    end

    context 'enters valid company information' do
      before do
        expect_any_instance_of(GitlabSubscriptions::CreateLeadService).to receive(:execute) do
          { success: true }
        end
      end

      it 'proceeds to the next step' do
        fill_in 'company_name', with: 'GitLab'
        select2 '1-99', from: '#company_size'
        fill_in 'phone_number', with: '+1 23 456-78-90'
        fill_in 'number_of_users', with: '1'
        select2 'US', from: '#country_select'

        click_button 'Continue'

        expect(page).not_to have_css('flash-container')
        expect(current_path).to eq(select_trials_path)
      end
    end

    context 'enters company information' do
      before do
        fill_in 'company_name', with: 'GitLab'
        select2 '1-99', from: '#company_size'
        fill_in 'number_of_users', with: '1'
        select2 'US', from: '#country_select'
      end

      context 'without phone number' do
        it 'shows validation error' do
          fill_in 'number_of_users', with: '1'

          click_button 'Continue'

          message = page.find('#phone_number').native.attribute('validationMessage')

          expect(message).to eq('Please fill out this field.')
          expect(current_path).to eq(new_trial_path)
        end
      end

      context 'with invalid phone number format' do
        it 'shows validation error' do
          fill_in 'number_of_users', with: '1'
          invalid_phone_numbers = [
            '+1 (121) 22-12-23',
            '+12190AX ',
            'Tel:129120',
            '11290+12'
          ]

          invalid_phone_numbers.each do |phone_number|
            fill_in 'phone_number', with: phone_number

            click_button 'Continue'

            message = page.find('#phone_number').native.attribute('validationMessage')

            expect(message).to eq('Please match the requested format.')
            expect(current_path).to eq(new_trial_path)
          end
        end
      end

      context 'and enters negative number to the number of users field' do
        it 'shows validation error' do
          fill_in 'number_of_users', with: '-1'

          click_button 'Continue'

          message = page.find('#number_of_users').native.attribute('validationMessage')

          expect(message).to eq('Value must be greater than or equal to 1.')
          expect(current_path).to eq(new_trial_path)
        end
      end
    end
  end
end
