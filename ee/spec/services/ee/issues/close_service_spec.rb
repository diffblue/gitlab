# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::CloseService do
  context 'sync requirement' do
    let(:requirement_initial_state) { 'opened' }
    let(:requirement_expected_state) { 'archived' }
    let(:issue_initial_state) { 'opened' }
    let(:issue_expected_state) { 'closed' }

    it_behaves_like 'sync requirement with issue state'
  end
end
