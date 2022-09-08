# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ProtectedEnvironments::SearchService, '#execute' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  subject { described_class.new(container: project, current_user: user).execute(environment_name) }

  before do
    %w(production staging review/App_1 review/app_2 test canary).each do |environment_name|
      create(:environment, name: environment_name, project: project)
    end

    create(:protected_environment, name: 'production', project: project)
    create(:protected_environment, name: 'staging', project: project)
  end

  context 'with empty search' do
    let(:environment_name) { '' }

    it 'returns unfiltered unprotected environments' do
      unprotected_environments = %w(review/App_1 review/app_2 test canary)

      expect(subject).to match_array(unprotected_environments)
    end
  end

  context 'with specific search' do
    let(:environment_name) { 'review/aPp' }

    it 'returns specific unprotected environments and matches case insensitively' do
      expect(subject).to match_array(['review/App_1', 'review/app_2'])
    end
  end

  context 'when no match' do
    let(:environment_name) { 'no_match' }

    it 'returns an empty array' do
      expect(subject).to eq([])
    end
  end
end
