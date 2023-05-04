# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranch::UnprotectAccessLevel, feature_category: :source_code_management do
  include_examples 'protected branch access'
  include_examples 'ee protected ref access', :protected_branch

  describe '::allowed_access_levels' do
    it 'does not include NO_ACCESS' do
      expect(described_class.allowed_access_levels).not_to include(Gitlab::Access::NO_ACCESS)
    end
  end
end
