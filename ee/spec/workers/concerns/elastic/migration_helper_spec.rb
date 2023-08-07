# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::MigrationHelper, feature_category: :global_search do
  let(:index_name) { 'index_name' }
  let(:helper) { Gitlab::Elastic::Helper.new }
  let(:migration_class) do
    Class.new do
      include Elastic::MigrationHelper
    end
  end

  subject { migration_class.new }

  before do
    allow(subject).to receive(:helper).and_return(helper)
  end

  describe '#get_number_of_shards' do
    let(:number_of_shards) { 10 }
    let(:settings) { { 'number_of_shards' => number_of_shards.to_s } }

    it 'uses get_settings' do
      expect(helper).to receive(:get_settings).with(index_name: index_name).and_return(settings)

      expect(subject.get_number_of_shards(index_name: index_name)).to eq(number_of_shards)
    end
  end

  describe '#get_max_slices' do
    using RSpec::Parameterized::TableSyntax

    before do
      allow(subject).to receive(:get_number_of_shards).with(index_name: index_name).and_return(number_of_shards)
    end

    where(:number_of_shards, :result) do
      nil | 2
      1   | 2
      2   | 2
      3   | 3
    end

    with_them do
      it 'returns correct max_slice' do
        expect(subject.get_max_slices(index_name: index_name)).to eq(result)
      end
    end
  end
end
