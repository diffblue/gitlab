# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::CustomBranchRule, feature_category: :source_code_management do
  subject(:instance) { Class.new.include(described_class).new }

  describe '#name' do
    it 'raises NotImplementedError' do
      expect { subject.name }.to raise_error(NotImplementedError)
    end
  end

  describe '#matching_branches_count' do
    it 'raises NotImplementedError' do
      expect { subject.matching_branches_count }.to raise_error(NotImplementedError)
    end
  end

  describe '#approval_project_rules?' do
    it 'raises NotImplementedError' do
      expect { subject.approval_project_rules }.to raise_error(NotImplementedError)
    end
  end

  describe '#external_status_checks' do
    it 'raises NotImplementedError' do
      expect { subject.external_status_checks }.to raise_error(NotImplementedError)
    end
  end
end
