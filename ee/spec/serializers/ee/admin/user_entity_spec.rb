# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admin::UserEntity do
  let_it_be(:user) { build_stubbed(:user) }

  let(:request) { double('request') }

  let(:entity) do
    described_class.new(user, request: request)
  end

  describe '#as_json' do
    subject { entity.as_json&.keys }

    it 'exposes correct attributes' do
      is_expected.to include(:oncall_schedules, :escalation_policies)
    end
  end
end
