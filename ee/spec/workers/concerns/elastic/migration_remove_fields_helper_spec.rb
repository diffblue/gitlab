# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::MigrationRemoveFieldsHelper, feature_category: :global_search do
  let(:migration_class) do
    Class.new do
      include Elastic::MigrationRemoveFieldsHelper
    end
  end

  subject { migration_class.new }

  describe '#index_name' do
    it 'raises a NotImplementedError' do
      expect { subject.index_name }.to raise_error(NotImplementedError)
    end
  end

  describe '#document_type' do
    it 'raises a NotImplementedError' do
      expect { subject.document_type }.to raise_error(NotImplementedError)
    end
  end

  describe '#fields_to_remove' do
    it 'raises a NotImplementedError' do
      expect { subject.fields_to_remove }.to raise_error(NotImplementedError)
    end
  end
end
