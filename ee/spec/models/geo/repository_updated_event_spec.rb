# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::RepositoryUpdatedEvent, type: :model, feature_category: :geo_replication do
  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
  end

  describe '#consumer_klass_name' do
    using RSpec::Parameterized::TableSyntax

    where(:source, :consumer_klass_name) do
      :design | 'DesignRepositoryUpdatedEvent'
      :repository | 'RepositoryUpdatedEvent'
      :wiki | 'RepositoryUpdatedEvent'
    end

    with_them do
      it 'returns the proper consumer class name' do
        subject.source = source

        expect(subject.consumer_klass_name).to eq consumer_klass_name
      end
    end
  end

  describe '#source' do
    it { is_expected.to define_enum_for(:source).with_values([:repository, :wiki, :design]) }
  end
end
