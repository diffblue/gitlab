# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Password::ComplexityValidator do
  describe '#validates_each' do
    let(:test_value) { '1' }
    let(:test_attribute) { :password }
    let(:user) { build(:user) }
    let(:validator) { described_class.new(attributes: [:password]) }

    context 'without any validation rule' do
      it 'is valid' do
        validator.validate_each(user, test_attribute, test_value)

        expect(user.errors.size).to be(0)
      end
    end

    context 'with a validation rule' do
      before do
        stub_application_setting(password_lowercase_required: true)
      end

      context 'when lowcase required rule is not matched' do
        it 'is invalid' do
          validator.validate_each(user, test_attribute, test_value)

          expect(user.errors.size).to be(1)
          expect(user.errors[:password]).to include(s_('Password|requires at least one lowercase letter'))
        end
      end

      context 'when lowcase required rule is matched' do
        let(:test_value) { 'a' }

        it 'is valid' do
          validator.validate_each(user, test_attribute, test_value)

          expect(user.errors.size).to be(0)
        end
      end
    end
  end

  describe '.required_complexity_rules' do
    context 'when no rules are enabled' do
      it 'returns an empty array' do
        expect(described_class.required_complexity_rules).to be_empty
        expect(described_class.required_complexity_rules).to be_an_instance_of(Array)
      end
    end

    context 'when lowcase required rule is enabled' do
      before do
        stub_application_setting(password_lowercase_required: true)
      end

      it 'returns a lowcase required rule' do
        expect(described_class.required_complexity_rules.size).to be(1)
        expect(described_class.required_complexity_rules[0][1])
          .to eq(s_('Password|requires at least one lowercase letter'))
      end
    end

    context 'when all rules are required' do
      before do
        stub_application_setting(password_number_required: true)
        stub_application_setting(password_symbol_required: true)
        stub_application_setting(password_lowercase_required: true)
        stub_application_setting(password_uppercase_required: true)
      end

      it 'returns 4 rules' do
        expect(described_class.required_complexity_rules.count).to eq(4)
      end
    end
  end
end
