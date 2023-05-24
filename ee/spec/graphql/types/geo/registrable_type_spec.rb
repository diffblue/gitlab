# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Geo::RegistrableType, feature_category: :geo_replication do
  describe '.resolve_type' do
    context 'when resolving a supported registry type' do
      include_context 'with geo registries shared context'

      with_them do
        it 'resolves to a Geo registry type' do
          resolved_type = described_class.resolve_type(build(registry_factory), {})

          expect(resolved_type).to be(registry_type)
        end
      end
    end

    context 'when resolving an unsupported registry type' do
      it 'raises a TypeNotSupportedError for string object' do
        expect do
          described_class.resolve_type('unrelated object', {})
        end.to raise_error(Types::Geo::RegistrableType::RegistryTypeNotSupportedError)
      end

      it 'raises a TypeNotSupportedError for nil object' do
        expect do
          described_class.resolve_type(nil, {})
        end.to raise_error(Types::Geo::RegistrableType::RegistryTypeNotSupportedError)
      end

      it 'raises a TypeNotSupportedError for other registry type' do
        expect do
          described_class.resolve_type(build(:geo_design_registry), {})
        end.to raise_error(Types::Geo::RegistrableType::RegistryTypeNotSupportedError)
      end
    end
  end
end
