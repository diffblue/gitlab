# frozen_string_literal: true

FactoryBot.define do
  factory :sbom_source, class: 'Sbom::Source' do
    source_type { :dependency_file }
    fingerprint { 'fingerprint' }

    source do
      {
        dependency_file: 'package-lock.json',
        package_manager_name: 'npm',
        language: 'JavaScript'
      }
    end
  end
end
