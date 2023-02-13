# frozen_string_literal: true

FactoryBot.define do
  factory :pm_checkpoint, class: 'PackageMetadata::Checkpoint' do
    sequence :purl_type, ::Enums::Sbom::PURL_TYPES.keys.cycle
    sequence(:sequence) { |n| start_sequence + n }
    sequence(:chunk) { |n| n }

    transient do
      start_sequence { 1000000000 }
    end
  end
end
