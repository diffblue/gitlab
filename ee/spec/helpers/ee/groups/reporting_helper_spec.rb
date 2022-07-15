# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Groups::ReportingHelper do
  describe '#numericality_validation_options' do
    let(:test_class) do
      Class.new do
        include ActiveModel::Validations

        validates :not_numerical, presence: true
        validates :incompatible_numerical, numericality: { equal_to: 5 }
        validates :between_numerical, numericality: { greater_than: 0, less_than: 10 }
        validates :between_or_equal_numerical, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }
        validates :range_numerical, numericality: { in: 0..10 }
      end
    end

    before do
      stub_const('TestClass', test_class)
    end

    subject { helper.numericality_validation_options(TestClass.new, attr) }

    context 'when attr does not have a numericality validator' do
      let(:attr) { :not_numerical }

      it { is_expected.to eq({}) }
    end

    context 'when attr has an incompatible numericality validator' do
      let(:attr) { :incompatible_numerical }

      it { is_expected.to eq({}) }
    end

    context 'when attr has a between numericality validator' do
      let(:attr) { :between_numerical }

      it { is_expected.to include(min: 0, max: 10, title: 'Between numerical must be between 0 and 10') }
    end

    context 'when attr has a between or equal numericality validator' do
      let(:attr) { :between_or_equal_numerical }

      it { is_expected.to include(min: 0, max: 10, title: 'Between or equal numerical must be between 0 and 10') }
    end

    context 'when attr has a range numericality validator' do
      let(:attr) { :range_numerical }

      it { is_expected.to include(min: 0, max: 10, title: 'Range numerical must be between 0 and 10') }
    end
  end
end
