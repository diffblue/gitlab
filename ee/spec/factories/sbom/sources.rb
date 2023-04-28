# frozen_string_literal: true

FactoryBot.define do
  factory :sbom_source, class: 'Sbom::Source' do
    source_type { :dependency_scanning }

    transient do
      sequence(:input_file_path) { |n| "subproject-#{n}/package-lock.json" }
      sequence(:source_file_path) { |n| "subproject-#{n}/package.json" }
      packager_name { 'npm' }
    end

    source do
      {
        'category' => 'development',
        'input_file' => { 'path' => input_file_path },
        'source_file' => { 'path' => source_file_path },
        'package_manager' => { 'name' => packager_name },
        'language' => { 'name' => 'JavaScript' }
      }
    end
  end
end
