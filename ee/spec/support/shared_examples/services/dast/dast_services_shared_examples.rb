# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'an error occurred in the execute method of dast service' do
  it 'communicates failure', :aggregate_failures do
    expect(subject).to be_error
    expect(subject.errors).to include(error_message)
  end
end

RSpec.shared_examples 'feature security_on_demand_scans is not available' do
  before do
    stub_licensed_features(security_on_demand_scans: false)
  end

  it_behaves_like 'an error occurred in the execute method of dast service' do
    let(:error_message) { 'Insufficient permissions' }
  end
end

RSpec.shared_examples 'when a user can not create_on_demand_dast_scan because they do not have access to a project' do
  let_it_be(:project) { create(:project) }

  it_behaves_like 'an error occurred in the execute method of dast service' do
    let(:error_message) { 'Insufficient permissions' }
  end
end
