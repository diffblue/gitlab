# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserIdExistenceValidator, feature_category: :insider_threat do
  let_it_be(:user) { create(:user) }

  let(:attr) { :git_rate_limit_users_alertlist }
  let(:validator) { described_class.new(attributes: [attr]) }
  let!(:application_setting) { build(:application_setting) }

  subject { validator.validate_each(application_setting, attr, value) }

  shared_examples 'does not add an error' do
    it 'does not add an error' do
      subject

      expect(application_setting.errors).to be_empty
    end
  end

  shared_examples 'does not trigger SQL queries' do
    it 'does not trigger SQL queries' do
      recorder = ActiveRecord::QueryRecorder.new { subject }

      expect(recorder.count).to be_zero
    end
  end

  context 'with nil value' do
    let(:value) { nil }

    it_behaves_like 'does not add an error'
    it_behaves_like 'does not trigger SQL queries'
  end

  context 'with non-array value' do
    let(:value) { 'foo' }

    it_behaves_like 'does not add an error'
    it_behaves_like 'does not trigger SQL queries'
  end

  context 'with empty array value' do
    let(:value) { [] }

    it_behaves_like 'does not add an error'
    it_behaves_like 'does not trigger SQL queries'
  end

  context 'with array containing valid user ids' do
    let(:value) { [user.id] }

    it_behaves_like 'does not add an error'
  end

  context 'with array containing invalid user ids' do
    let(:value) { [non_existing_record_id, user.id] }

    it 'adds an error' do
      subject

      expected_error = "should be an array of existing user ids. #{non_existing_record_id} does not exist"
      expect(application_setting.errors[attr].first).to match(expected_error)
    end
  end
end
