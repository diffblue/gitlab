# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'trials/new.html.haml' do
  include ApplicationHelper
  let_it_be(:variant) { :control }
  let_it_be(:user) { build(:user) }

  before do
    allow(view).to receive(:current_user) { user }
    allow(view).to receive(:remove_known_trial_form_fields_variant).and_return(variant)

    render
  end

  subject { rendered }

  it 'has fields for first, last company name and size', :aggregate_failures do
    is_expected.to have_field('first_name')
    is_expected.to have_field('last_name')
    is_expected.to have_field('company_name')
    sizes = ['Please select', '1 - 99', '100 - 499', '500 - 1,999', '2,000 - 9,999', '10,000 +']
    is_expected.to have_select('company_size', options: sizes, selected: [])
  end

  context 'remove_known_trial_form_fields noneditable experiment is enabled' do
    let_it_be(:variant) { :noneditable }

    it { is_expected.to have_content('Your GitLab Ultimate trial lasts for 30 days, but you can keep your free GitLab account forever. We just need some additional information to activate your trial.') }

    context 'the user has already values in first, last and company names' do
      let_it_be(:user) { build(:user, first_name: 'John', last_name: 'Doe', organization: 'ACME') }

      it 'has readonly fields', :aggregate_failures do
        is_expected.to have_field('first_name', readonly: true)
        is_expected.to have_field('last_name', readonly: true)
        is_expected.to have_field('company_name', readonly: true)
      end
    end

    context 'the user empty values for first, last and company names' do
      let_it_be(:user) { build(:user, first_name: '', last_name: '', organization: '') }

      it 'has fields', :aggregate_failures do
        is_expected.to have_field('first_name')
        is_expected.to have_field('last_name')
        is_expected.to have_field('company_name')
      end
    end
  end

  context 'remove_known_trial_form_fields welcoming experiment is enabled' do
    let_it_be(:variant) { :welcoming }

    context 'the user has already values in first, last and company names' do
      let_it_be(:user) { build(:user, first_name: 'John', last_name: 'Doe', organization: 'ACME') }

      it { is_expected.to have_content('Hi John, your GitLab Ultimate trial lasts for 30 days, but you can keep your free GitLab account forever. We just need some additional information about ACME to activate your trial.') }
      it 'has hidden fields' do
        is_expected.to have_field('first_name', type: :hidden)
        is_expected.to have_field('last_name', type: :hidden)
        is_expected.to have_field('company_name', type: :hidden)
      end
    end
    context 'the user empty values for first, last and company names' do
      let_it_be(:user) { build(:user, first_name: '', last_name: '', organization: '') }

      it { is_expected.to have_content('Hi, your GitLab Ultimate trial lasts for 30 days, but you can keep your free GitLab account forever. We just need some additional information about your company to activate your trial.') }
      it 'has fields' do
        is_expected.to have_field('first_name')
        is_expected.to have_field('last_name')
        is_expected.to have_field('company_name')
      end
    end
  end
end
