# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'it attempts to associate the profile' do |dast_profile_name_key|
  let(:association) { dast_build.public_send(profile.class.underscore.to_sym) }
  let(:profile_name) { public_send(dast_profile_name_key) }

  context 'when the profile exists' do
    it 'assigns the association' do
      expect(association).to eq(profile)
    end
  end

  shared_examples 'it has no effect' do
    it 'does not assign the association' do
      expect(association).to be_nil
    end
  end

  context 'when the profile is not provided' do
    let(dast_profile_name_key) { nil }

    it_behaves_like 'it has no effect'
  end

  context 'when the profile does not exist' do
    let(dast_profile_name_key) { SecureRandom.hex }

    it_behaves_like 'an error occurred during the dast profile association' do
      let(:error_message) { "DAST profile not found: #{profile_name}" }
    end
  end
end

RSpec.shared_examples 'an error occurred' do
  it 'communicates failure', :aggregate_failures do
    expect(subject).to be_error
    expect(subject.errors).to include(error_message)
  end
end

RSpec.shared_examples 'an error occurred during the dast profile association' do
  it_behaves_like 'an error occurred'
end
