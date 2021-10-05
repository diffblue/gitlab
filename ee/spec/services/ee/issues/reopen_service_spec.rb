# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::ReopenService do
  context 'sync requirement' do
    let(:requirement_initial_state) { 'archived' }
    let(:requirement_expected_state) { 'opened' }
    let(:issue_initial_state) { 'closed' }
    let(:issue_expected_state) { 'opened' }

    it_behaves_like 'sync requirement with issue state'
  end
end
