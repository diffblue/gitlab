# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Database::GitlabSchema do
  describe '.tables_to_schema' do
    it 'all tables are unique' do
      table_names = YAML.load_file(Rails.root.join(described_class::GITLAB_SCHEMAS_FILE)).keys
      ee_table_names = YAML.load_file(Rails.root.join(described_class::EE_GITLAB_SCHEMAS_FILE)).keys
      duplicated_tables = table_names & ee_table_names

      expect(duplicated_tables).to be_empty, \
        "Duplicated table(s) #{duplicated_tables.to_a} found in #{described_class}.tables_to_schema. " \
        "Any duplicated table must be removed from #{described_class::GITLAB_SCHEMAS_FILE} or " \
        "#{described_class::EE_GITLAB_SCHEMAS_FILE}."
    end

    context "for geo using Geo::TrackingBase" do
      let(:db_class) { Geo::TrackingBase }
      let(:db_data_sources) { db_class.connection.data_sources }
      let(:gitlab_schemas) { [:gitlab_internal, :gitlab_geo] }

      # The Geo database does not share the same structure as all decomposed databases
      subject { described_class.tables_to_schema.select { |_, v| gitlab_schemas.include?(v) } }

      it 'new data sources are added' do
        missing_tables = db_data_sources.to_set - subject.keys

        expect(missing_tables).to be_empty, \
          "Missing table(s) #{missing_tables.to_a} not found in #{described_class}.tables_to_schema. " \
          "Any new tables must be added to #{described_class::EE_GITLAB_SCHEMAS_FILE}."
      end

      it 'non-existing data sources are removed' do
        extra_tables = subject.keys.to_set - db_data_sources

        expect(extra_tables).to be_empty, \
          "Extra table(s) #{extra_tables.to_a} found in #{described_class}.tables_to_schema. " \
          "Any removed or renamed tables must be removed from #{described_class::EE_GITLAB_SCHEMAS_FILE}."
      end
    end
  end

  describe '.table_schema' do
    using RSpec::Parameterized::TableSyntax

    where(:name, :classification) do
      'project_registry'           | :gitlab_geo
      'my_schema.project_registry' | :gitlab_geo
    end

    with_them do
      subject { described_class.table_schema(name) }

      it { is_expected.to eq(classification) }
    end
  end
end
