# frozen_string_literal: true

require 'fast_spec_helper'
require_dependency 'action_controller'

RSpec.describe Gitlab::Insights::Validators::ParamsValidator do
  subject { described_class.new(params).validate! }

  describe ':type' do
    described_class::SUPPORTER_TYPES.each do |type|
      context "with type: '#{type}'" do
        let(:params) do
          { type: type }
        end

        it 'does not raise an error' do
          expect { subject }.not_to raise_error
        end
      end
    end

    context 'with an invalid :type' do
      let(:params) do
        { type: 'unknown' }
      end

      it 'raises an error' do
        expect { subject }.to raise_error(described_class::InvalidTypeError, "Invalid `:type`: `unknown`. Allowed values are #{described_class::SUPPORTER_TYPES}!")
      end
    end
  end

  describe ':projects' do
    let(:base_params) { { type: described_class::SUPPORTER_TYPES.first } }

    context 'when projects is an array' do
      let(:params) do
        base_params.merge(projects: [])
      end

      it 'raises an error' do
        expect { subject }.to raise_error(described_class::InvalidProjectsError, "Invalid `:projects`: `[]`. It should be a hash.")
      end
    end

    context 'when projects is a hash, having `only` with an integer' do
      let(:params) do
        base_params.merge(projects: { only: 1 })
      end

      it 'raises an error' do
        expect { subject }.to raise_error(described_class::InvalidProjectsError, "Invalid `:projects`.`only`: `1`. It should be an array.")
      end
    end

    context 'when projects is a hash, having `only` with an array' do
      let(:params) do
        base_params.merge(projects: { only: [] })
      end

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end
  end
end
