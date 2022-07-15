# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::SecureFile do
  using RSpec::Parameterized::TableSyntax
  include EE::GeoHelpers

  let(:project) { create(:project) }

  include_examples 'a replicable model with a separate table for verification state' do
    before do
      stub_ci_secure_file_object_storage
    end

    let(:verifiable_model_record) { create(:ci_secure_file, project: project) }
    let(:unverifiable_model_record) { create(:ci_secure_file, :remote_store, project: project) }
  end

  describe '#replicables_for_current_secondary' do
    # Selective sync is configured relative to the secure file's project.
    #
    # Permutations of sync_object_storage combined with object-stored-artifacts
    # are tested in code, because the logic is simple, and to do it in the table
    # would quadruple its size and have too much duplication.
    where(:selective_sync_namespaces, :selective_sync_shards, :factory, :project_factory, :include_expectation) do
      nil                  | nil    | [:ci_secure_file]           | [:project]               | true
      # selective sync by shard
      nil                  | :model | [:ci_secure_file]           | [:project]               | true
      nil                  | :other | [:ci_secure_file]           | [:project]               | false
      # selective sync by namespace
      :model_parent        | nil    | [:ci_secure_file]           | [:project]               | true
      :model_parent_parent | nil    | [:ci_secure_file]           | [:project, :in_subgroup] | true
      :other               | nil    | [:ci_secure_file]           | [:project]               | false
      :other               | nil    | [:ci_secure_file]           | [:project, :in_subgroup] | false
    end

    with_them do
      subject(:ci_secure_file_included) { described_class.replicables_for_current_secondary(ci_secure_file).exists? }

      let(:project) { create(*project_factory) } # rubocop:disable Rails/SaveBang
      let(:node) do
        create(:geo_node_with_selective_sync_for,
               model: project,
               namespaces: selective_sync_namespaces,
               shards: selective_sync_shards,
               sync_object_storage: sync_object_storage)
      end

      before do
        stub_ci_secure_file_object_storage
        stub_current_geo_node(node)
      end

      context 'when sync object storage is enabled' do
        let(:sync_object_storage) { true }

        context 'when the ci secure file is locally stored' do
          before do
            stub_ci_secure_file_object_storage(enabled: false)
          end

          let(:ci_secure_file) { create(*factory, project: project) }

          it { is_expected.to eq(include_expectation) }
        end

        context 'when the ci secure file is object stored' do
          let(:ci_secure_file) { create(*factory, :remote_store, project: project) }

          it { is_expected.to eq(include_expectation) }
        end
      end

      context 'when sync object storage is disabled' do
        let(:sync_object_storage) { false }

        context 'when the ci secure file is locally stored' do
          before do
            stub_ci_secure_file_object_storage(enabled: false)
          end

          let(:ci_secure_file) { create(*factory, project: project) }

          it { is_expected.to eq(include_expectation) }
        end

        context 'when the ci secure file is object stored' do
          let(:ci_secure_file) { create(*factory, :remote_store, project: project) }

          it { is_expected.to be_falsey }
        end
      end
    end
  end
end
