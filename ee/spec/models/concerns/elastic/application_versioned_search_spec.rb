# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::ApplicationVersionedSearch, feature_category: :global_search do
  include ElasticsearchHelpers

  let(:klass) do
    Class.new(ApplicationRecord) do
      self.table_name = 'issues'
      def self.name
        'Issue'
      end

      include Elastic::ApplicationVersionedSearch

      has_many :widgets
    end
  end

  describe '.elastic_index_dependant_association' do
    it 'adds the associations to elastic_index_dependants' do
      klass.elastic_index_dependant_association(:widgets, on_change: :title, depends_on_finished_migration: :test_migration)

      expect(klass.elastic_index_dependants).to include({
        association_name: :widgets,
        on_change: :title,
        depends_on_finished_migration: :test_migration
      })
    end

    context 'when the association does not exist' do
      it 'raises an error' do
        expect { klass.elastic_index_dependant_association(:foo_bars, on_change: :bar) }
          .to raise_error("Invalid association to index. \"foo_bars\" is either not a collection or not an association. Hint: You must declare the has_many before declaring elastic_index_dependant_association.")
      end
    end

    context 'when the class is not an ApplicationRecord' do
      let(:not_application_record) do
        Class.new do
          include Elastic::ApplicationVersionedSearch
        end
      end

      it 'raises an error' do
        expect { not_application_record.elastic_index_dependant_association(:widgets, on_change: :title) }
          .to raise_error("elastic_index_dependant_association is not applicable as this class is not an ActiveRecord model.")
      end
    end
  end

  describe '.associations_needing_elasticsearch_update' do
    context 'when elastic_index_dependents is empty' do
      it 'returns an empty array' do
        expect(klass.new.associations_needing_elasticsearch_update(['title'])).to match_array []
      end
    end

    context 'when updated_attributes does not contains on_change attribute' do
      it 'returns an empty array' do
        klass.elastic_index_dependant_association :widgets, on_change: :name
        expect(klass.new.associations_needing_elasticsearch_update(['title'])).to match_array []
      end
    end

    context 'when updated_attributes contains on_change attribute' do
      it 'returns an array with widgets' do
        klass.elastic_index_dependant_association :widgets, on_change: :title
        expect(klass.new.associations_needing_elasticsearch_update(['title'])).to match_array ['widgets']
      end
    end

    context 'when depends_on_finished_migration migration is not finished' do
      it 'returns an empty array' do
        last_migration = Elastic::DataMigrationService.migrations.last.name_for_key.to_sym
        klass.elastic_index_dependant_association :widgets, on_change: :title, depends_on_finished_migration: last_migration
        set_elasticsearch_migration_to last_migration, including: false
        expect(klass.new.associations_needing_elasticsearch_update(['title'])).to match_array []
      end
    end

    context 'when depends_on_finished_migration migration is finished' do
      it 'returns an array with widgets' do
        last_migration = Elastic::DataMigrationService.migrations.last.name_for_key.to_sym
        klass.elastic_index_dependant_association :widgets, on_change: :title, depends_on_finished_migration: last_migration
        set_elasticsearch_migration_to last_migration, including: true
        expect(klass.new.associations_needing_elasticsearch_update(['title'])).to match_array ['widgets']
      end
    end
  end
end
