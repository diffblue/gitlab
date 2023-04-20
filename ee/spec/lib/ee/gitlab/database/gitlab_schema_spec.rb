# frozen_string_literal: true
require 'spec_helper'

RSpec.shared_examples 'validate path globs' do |path_globs|
  it 'returns an array of path globs' do
    expect(path_globs).to be_an(Array)
    expect(path_globs).to all(be_an(Pathname))
  end
end

RSpec.describe Gitlab::Database::GitlabSchema do
  describe '.views_and_tables_to_schema' do
    it 'all tables and views are unique' do
      table_names = load_schemas(described_class::DICTIONARY_PATH).keys
      ee_table_names = Gitlab::Database::EE_DATABASES_NAME_TO_DIR
                         .flat_map do |_, ee_db_dir|
                           load_schemas(ee_db_dir).keys
                         end
      duplicated_tables = table_names & ee_table_names

      expect(duplicated_tables).to be_empty, \
        "Duplicated table(s) #{duplicated_tables.to_a} found in #{described_class}.views_and_tables_to_schema. " \
        "Any duplicated table must be removed from db/docs/ or ee/db/docs/. " \
        "More info: https://docs.gitlab.com/ee/development/database/database_dictionary.html"
    end

    context "for geo using Geo::TrackingBase" do
      let(:db_class) { Geo::TrackingBase }
      let(:db_data_sources) { db_class.connection.data_sources }
      let(:gitlab_schemas) { [:gitlab_internal, :gitlab_geo] }

      # The Geo database does not share the same structure as all decomposed databases
      subject { described_class.views_and_tables_to_schema.select { |_, v| gitlab_schemas.include?(v) } }

      it 'new data sources are added' do
        missing_data_sources = db_data_sources.to_set - subject.keys

        expect(missing_data_sources).to be_empty, \
          "Missing table/view(s) #{missing_data_sources.to_a} not found in " \
          "#{described_class}.views_and_tables_to_schema. Any new tables or views " \
          "must be added to the database dictionary. More info: " \
          "https://docs.gitlab.com/ee/development/database/database_dictionary.html"
      end

      it 'non-existing data sources are removed' do
        extra_data_sources = subject.keys.to_set - db_data_sources

        expect(extra_data_sources).to be_empty, \
          "Extra table/view(s) #{extra_data_sources.to_a} found in #{described_class}.views_and_tables_to_schema. " \
          "Any removed or renamed tables or views must be removed from the database dictionary" \
          "More info: https://docs.gitlab.com/ee/development/database/database_dictionary.html"
      end
    end
  end

  describe '.dictionary_path_globs' do
    include_examples 'validate path globs', described_class.dictionary_path_globs
  end

  describe '.view_path_globs' do
    include_examples 'validate path globs', described_class.view_path_globs
  end

  describe '.deleted_tables_path_globs' do
    include_examples 'validate path globs', described_class.deleted_tables_path_globs
  end

  describe '.deleted_views_path_globs' do
    include_examples 'validate path globs', described_class.deleted_views_path_globs
  end

  describe '.tables_to_schema' do
    let(:database_models) { Gitlab::Database.database_base_models.slice('geo') }
    let(:views) { database_models.flat_map { |_, m| m.connection.views }.sort.uniq }

    subject { described_class.tables_to_schema }

    it 'returns only tables' do
      tables = subject.keys

      expect(tables).not_to include(views.to_set)
    end
  end

  describe '.views_to_schema' do
    let(:database_models) { Gitlab::Database.database_base_models.slice('geo') }
    let(:tables) { database_models.flat_map { |_, m| m.connection.tables }.sort.uniq }

    subject { described_class.views_to_schema }

    it 'returns only views' do
      views = subject.keys

      expect(views).not_to include(tables.to_set)
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

  def load_schemas(dictionary_path)
    tables_schema = Dir[Rails.root.join(dictionary_path, '*.yml')].each_with_object({}) do |file_path, dic|
      data = YAML.load_file(file_path)

      next if data['gitlab_schema'] == 'gitlab_internal'

      dic[data['table_name']] = data['gitlab_schema'].to_sym
    end

    views_schema = Dir[Rails.root.join(dictionary_path, 'views', '*.yml')].each_with_object({}) do |file_path, dic|
      data = YAML.load_file(file_path)

      dic[data['view_name']] = data['gitlab_schema'].to_sym
    end

    tables_schema.merge(views_schema)
  end
end
