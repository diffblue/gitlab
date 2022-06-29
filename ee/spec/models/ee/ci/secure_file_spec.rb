# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::SecureFile do
  using RSpec::Parameterized::TableSyntax
  include EE::GeoHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  include_examples 'a replicable model with a separate table for verification state' do
    before do
      stub_ci_secure_file_object_storage
    end

    let(:verifiable_model_record) { build(:ci_secure_file, project: project) }
    let(:unverifiable_model_record) { build(:ci_secure_file, project: project) }
  end
end
