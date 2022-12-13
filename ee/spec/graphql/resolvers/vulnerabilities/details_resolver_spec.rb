# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Vulnerabilities::DetailsResolver, feature_category: :vulnerability_management do
  include GraphqlHelpers

  describe '.with_field_name' do
    subject { described_class.with_field_name(items) }

    context 'when there are no items' do
      let(:items) { nil }

      it { is_expected.to eq([]) }
    end

    context 'when there are items with field name' do
      let(:items) do
        {
          field: {
            value: :x
          },
          field_2: {
            value: :y
          }
        }
      end

      it { is_expected.to eq([{ value: :x, field_name: :field }, { value: :y, field_name: :field_2 }]) }
    end
  end

  describe '#resolve' do
    subject { resolve(described_class, obj: vulnerability, args: {}, ctx: {}) }

    let(:vulnerability) { double(finding_details: finding_details) }

    context 'when there are no items in finding details' do
      let(:finding_details) { nil }

      it { is_expected.to eq([]) }
    end

    context 'when there are items in finding details' do
      let(:finding_details) do
        {
          field: {
            value: :x
          },
          field_2: {
            value: :y
          }
        }
      end

      it { is_expected.to eq([{ 'field_name' => 'field', 'value' => :x }, { 'field_name' => 'field_2', 'value' => :y }]) }
    end
  end
end
