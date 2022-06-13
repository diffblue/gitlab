# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MigrationsHelpers do
  let(:helper_class) do
    Class.new.tap do |klass|
      klass.include described_class
      allow(klass).to receive(:metadata).and_return(metadata)
    end
  end

  let(:metadata) { {} }
  let(:helper) { helper_class.new }

  describe '#active_record_base' do
    it 'returns the main base model' do
      expect(helper.active_record_base).to eq(ActiveRecord::Base)
    end
  end

  describe '#table' do
    it 'creates a class based on main base model' do
      klass = helper.table(:projects)
      expect(klass.connection_specification_name).to eq('ActiveRecord::Base')
    end
  end
end
