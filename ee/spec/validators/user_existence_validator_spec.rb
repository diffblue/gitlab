# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserExistenceValidator do
  let_it_be(:user) { create(:user) }

  let(:attr) { :git_rate_limit_users_allowlist }
  let(:validator) { described_class.new(attributes: [attr]) }
  let!(:application_setting) { build(:application_setting) }

  subject { validator.validate_each(application_setting, attr, value) }

  shared_examples 'does not add an error' do
    it 'does not add an error' do
      subject

      expect(application_setting.errors).to be_empty
    end
  end

  context 'with nil value' do
    let(:value) { nil }

    it_behaves_like 'does not add an error'
  end

  context 'with non-array value' do
    let(:value) { 'foo' }

    it_behaves_like 'does not add an error'
  end

  context 'with empty array value' do
    let(:value) { [] }

    it_behaves_like 'does not add an error'

    it 'does not trigger SQL queries' do
      recorder = ActiveRecord::QueryRecorder.new { subject }

      expect(recorder.count).to be_zero
    end
  end

  context 'with array containing valid usernames' do
    let(:value) { [user.username] }

    it_behaves_like 'does not add an error'
  end

  context 'with array containing invalid usernames' do
    let(:value) { ['non_existent', user.username] }

    it 'does adds an error' do
      subject

      expected_error = "should be an array of existing usernames. non_existent does not exist"
      expect(application_setting.errors[attr].first).to match(expected_error)
    end
  end
end
