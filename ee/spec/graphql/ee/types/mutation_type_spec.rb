# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::MutationType do
  describe 'deprecated mutations' do
    describe 'iterationCreate' do
      let(:field) { get_field('iterationCreate') }

      it { expect(field.deprecation_reason).to eq('Manual iteration management is deprecated. Only automatic iteration cadences will be supported in the future. Deprecated in 14.10.') }
    end

    describe 'createIteration' do
      let(:field) { get_field('createIteration') }

      it { expect(field.deprecation_reason).to eq('Manual iteration management is deprecated. Only automatic iteration cadences will be supported in the future. Deprecated in 14.0.') }
    end
  end

  def get_field(name)
    described_class.fields[GraphqlHelpers.fieldnamerize(name)]
  end
end
