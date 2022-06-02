# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedEnvironments::Entity do
  describe '#as_json' do
    it 'includes the exposed fields' do
      protected_environment = build(:protected_environment)
      output = described_class.new(protected_environment).as_json

      expect(output).to include(:id, :project_id, :name, :group_id)
    end
  end
end
