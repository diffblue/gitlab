# frozen_string_literal: true

FactoryBot.define do
  factory :pm_checkpoint, class: 'PackageMetadata::Checkpoint' do
    # This factory can only be used 12 times in a row without more complex sequences
    sequence :purl_type, ::Enums::Sbom::PURL_TYPES.keys.cycle
    sequence :data_type, ::Enums::PackageMetadata::DATA_TYPES.keys.cycle
    sequence :version_format, ::Enums::PackageMetadata::VERSION_FORMATS.keys.cycle
    sequence(:sequence) { |n| start_sequence + n }
    sequence(:chunk) { |n| n }

    transient do
      start_sequence { 1000000000 }
    end
  end
end
