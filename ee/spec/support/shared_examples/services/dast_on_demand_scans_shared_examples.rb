# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'it delegates scan creation to another service' do
  it 'calls AppSec::Dast::Scans::CreateService' do
    expect(AppSec::Dast::Scans::CreateService).to receive(:new).with(hash_including(params: delegated_params)).and_call_original

    subject
  end
end

RSpec.shared_examples 'it checks branch permissions before creating a DAST on-demand scan pipeline' do
  let(:other_user) { create(:user) }
  let(:branch_name) { 'protected_branch' }

  context 'when the user does not have access to the branch' do
    before do
      create(:protected_branch, project: project, name: branch_name)
      project.repository.add_branch(other_user, branch_name, 'master')
    end

    it 'communicates failure' do
      expect(subject[:errors]).to include(a_string_including("You do not have sufficient permission to run a pipeline on '#{branch_name}'"))
    end
  end
end
