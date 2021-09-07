# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CombinedRegistrationExperiment, :experiment do
  subject { described_class.new(user: user) }

  let_it_be(:user) { create(:user) }

  describe '#signature' do
    let(:force_company_trial) { experiment(:force_company_trial, user: user) }

    it 'returns the same context key for force_company_trial' do
      expect(subject.signature[:key]).not_to be_nil
      expect(subject.signature[:key]).to eq(force_company_trial.signature[:key])
    end
  end

  describe '#redirect_path' do
    it 'when control passes trial_params to path' do
      stub_experiments(combined_registration: :control)

      expect(subject.redirect_path(trial: true)).to eq(Rails.application.routes.url_helpers.new_users_sign_up_group_path(trial: true))
    end

    it 'when candidate returns path' do
      stub_experiments(combined_registration: :candidate)

      expect(subject.redirect_path(trial: true)).to eq(Rails.application.routes.url_helpers.new_users_sign_up_groups_project_path)
    end
  end
end
