# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::TodoableInterface do
  let(:extended_class) { described_class }

  describe ".resolve_type" do
    it 'knows the correct type for EE-only objects' do
      expect(extended_class.resolve_type(build(:epic), {})).to eq(Types::EpicType)
    end
  end
end
