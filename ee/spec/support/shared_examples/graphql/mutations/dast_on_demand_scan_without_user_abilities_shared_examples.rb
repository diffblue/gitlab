# frozen_string_literal: true

require 'spec_helper'

# There must be a method or let named `mutation` defined that executes the
# mutation and one named `mutation_name` that is the name of the mutation being
# executed. There must also be method or let named `project` and one named
# `current_user.`
RSpec.shared_examples 'an on-demand scan mutation when user cannot run an on-demand scan' do
  let_it_be(:full_path) { project.full_path }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  context 'when a user does not have access to the project' do
    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when a user does not have access to run a dast scan on the project' do
    before do
      project.add_guest(current_user)
    end

    it_behaves_like 'a mutation that returns a top-level access error'
  end
end
