# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BridgePolicy, feature_category: :continuous_integration do
  it_behaves_like 'a deployable job policy in EE', :ci_bridge
end
