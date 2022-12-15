# frozen_string_literal: true

RSpec.shared_examples 'a framework registry finder' do |registry_factory|
  include ::EE::GeoHelpers

  let(:replicator_class) { Gitlab::Geo::Replicator.for_class_name(described_class.name) }
  let(:model_class) { replicator_class.model }
  let(:factory_traits) { replicator_class.verification_enabled? ? [:synced, :verification_succeeded] : [:synced] }

  # rubocop:disable Rails/SaveBang
  let!(:registry1) { create(registry_factory, :synced) }
  let!(:registry2) { create(registry_factory, *factory_traits) }
  let!(:registry3) { create(registry_factory) }
  let!(:registry4) { create(registry_factory, *factory_traits) }
  # rubocop:enable Rails/SaveBang

  let(:params) { {} }

  subject(:registries) { described_class.new(user, params).execute }

  describe '#execute' do
    context 'when user cannot read all Geo' do
      let_it_be(:user) { create(:user) }

      it { is_expected.to be_empty }
    end

    context 'when user can read all Geo' do
      let_it_be(:user) { create(:user, :admin) }

      context 'when admin mode is disabled' do
        it { is_expected.to be_empty }
      end

      context 'when admin mode is enabled', :enable_admin_mode do
        context 'with an ids param' do
          let(:params) { { ids: [registry3.id, registry1.id] } }

          it 'returns specified registries' do
            expect(registries.to_a).to contain_exactly(registry1, registry3)
          end
        end

        context 'with an ids param empty' do
          let(:params) { { ids: [] } }

          it 'returns all registries' do
            expect(registries.to_a).to contain_exactly(registry1, registry2, registry3, registry4)
          end
        end

        context 'with a replication_state param' do
          let(:params) { { replication_state: :synced } }

          it 'returns registries with requested replication state' do
            expect(registries.to_a).to contain_exactly(registry1, registry2, registry4)
          end
        end

        context 'with a replication_state param empty' do
          let(:params) { { replication_state: '' } }

          it 'returns all registries' do
            expect(registries.to_a).to contain_exactly(registry1, registry2, registry3, registry4)
          end
        end

        context 'with verification enabled' do
          before do
            skip_if_verification_is_not_enabled
          end

          context 'with a verification_state param' do
            let(:params) { { verification_state: :succeeded } }

            it 'returns registries with requested verification state' do
              expect(registries.to_a).to contain_exactly(registry2, registry4)
            end
          end

          context 'with a verification_state param empty' do
            let(:params) { { verification_state: '' } }

            it 'returns all registries' do
              expect(registries.to_a).to contain_exactly(registry1, registry2, registry3, registry4)
            end
          end
        end

        context 'with verification disabled' do
          before do
            skip_if_verification_is_enabled
          end

          context 'with a verification_state param' do
            let(:params) { { verification_state: :succeeded } }

            it 'raises ArgumentError' do
              expect { registries }.to raise_error(ArgumentError)
            end
          end

          context 'with a verification_state param empty' do
            let(:params) { { verification_state: '' } }

            it 'raises ArgumentError' do
              message = "Filtering by verification_state is not supported " \
                "because verification is not enabled for #{replicator_class.model}"

              expect { registries }.to raise_error(ArgumentError, message)
            end
          end
        end

        context 'when search method is not implemented in the registry model' do
          let(:params) { { keyword: 'any_keyword' } }

          before do
            skip "Skipping because search method is implemented for #{model_class}" if model_class.respond_to?(:search)
          end

          it 'raises ArgumentError' do
            message = "Filtering by keyword is not supported " \
              "because search method is not implemented for #{replicator_class.model}"

            expect { registries }.to raise_error(ArgumentError, message)
          end
        end

        context 'when search method is implemented in the registry model' do
          let(:registry5) { create(registry_factory) } # rubocop:disable Rails/SaveBang
          let(:replicable_record) { registry5.replicator.model_record }
          let(:params) { { keyword: 'any_keyword' } }

          def searchable_attributes
            if model_class.const_defined?(:EE_SEARCHABLE_ATTRIBUTES)
              model_class::EE_SEARCHABLE_ATTRIBUTES
            else
              []
            end
          end

          before do
            if !model_class.respond_to?(:search) || searchable_attributes.empty?
              skip "Skipping because search method is not implemented
                      for #{model_class} or searchable attributes are not defined."
            end

            # Use update_column to bypass attribute validations like regex formatting, checksum, etc.
            replicable_record.update_column(searchable_attributes[0], 'any_keyword')
          end

          it 'returns a registry filtered by keyword' do
            expect(registries.to_a).to contain_exactly(registry5)
          end
        end

        context 'with no params' do
          it 'returns all registries' do
            expect(registries.to_a).to contain_exactly(registry1, registry2, registry3, registry4)
          end
        end
      end
    end
  end
end
