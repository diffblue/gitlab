# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranch::UnprotectAccessLevel, feature_category: :source_code_management do
  it { is_expected.to validate_inclusion_of(:access_level).in_array([Gitlab::Access::MAINTAINER, Gitlab::Access::DEVELOPER]) }
  it { is_expected.not_to allow_value(Gitlab::Access::NO_ACCESS).for(:access_level) }
end
