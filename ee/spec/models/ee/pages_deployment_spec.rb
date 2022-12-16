# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PagesDeployment do
  using RSpec::Parameterized::TableSyntax
  include EE::GeoHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  describe '#save_verification_details' do
    let(:verifiable_model_record) { build(:pages_deployment) }
    let(:verification_state_table_class) { verifiable_model_record.class.verification_state_table_class }

    context 'when model_record is part of available_verifiables scope' do
      it 'creates verification details' do
        expect { verifiable_model_record.save! }.to change { verification_state_table_class.count }.by(1)
      end
    end
  end

  describe '.replicables_for_current_secondary' do
    where(:selective_sync_enabled, :object_storage_sync_enabled, :pages_object_storage_enabled, :synced_pages) do
      true  | true  | true  | 5
      true  | true  | false | 5
      true  | false | true  | 0
      true  | false | false | 5
      false | true  | true  | 10
      false | true  | false | 10
      false | false | true  | 0
      false | false | false | 10
    end

    with_them do
      let(:secondary) do
        node = build(:geo_node, sync_object_storage: object_storage_sync_enabled)

        if selective_sync_enabled
          node.selective_sync_type = 'namespaces'
          node.namespaces = [group]
        end

        node.save!
        node
      end

      before do
        stub_current_geo_node(secondary)
        stub_pages_object_storage(::Pages::DeploymentUploader) if pages_object_storage_enabled

        create_list(:pages_deployment, 5, project: project)
        create_list(:pages_deployment, 5, project: create(:project))
      end

      it 'returns the proper number of pages deployments' do
        expect(described_class.replicables_for_current_secondary(1..described_class.last.id).count).to eq(synced_pages)
      end
    end
  end

  describe '.search' do
    let_it_be(:pages_deployment1) { create(:pages_deployment) }
    let_it_be(:pages_deployment2) { create(:pages_deployment) }

    context 'when search query is empty' do
      it 'returns all records' do
        result = described_class.search('')

        expect(result).to contain_exactly(pages_deployment1, pages_deployment2)
      end
    end

    context 'when search query is not empty' do
      context 'without matches' do
        it 'filters all records' do
          result = described_class.search('something_that_does_not_exist')

          expect(result).to be_empty
        end
      end

      context 'with matches by attributes' do
        where(:searchable_attribute) { described_class::EE_SEARCHABLE_ATTRIBUTES }

        before do
          # Use update_column to bypass attribute validations like regex formatting, checksum, etc.
          pages_deployment1.update_column(searchable_attribute, 'any_keyword')
        end

        with_them do
          it do
            result = described_class.search('any_keyword')

            expect(result).to contain_exactly(pages_deployment1)
          end
        end
      end
    end
  end
end
