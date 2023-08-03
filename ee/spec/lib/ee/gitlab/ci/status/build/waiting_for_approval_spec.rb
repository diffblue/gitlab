# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Build::WaitingForApproval, feature_category: :deployment_management do
  it_behaves_like 'a deployment job waiting for approval', :ci_build
end
