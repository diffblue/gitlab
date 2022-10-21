# frozen_string_literal: true

FactoryBot.define do
  factory :dependency, class: 'Hash' do
    sequence(:name) { |n| "library#{n}" }
    packager { 'Ruby (Bundler)' }
    package_manager { 'Ruby (Bundler)' }
    version { '1.8.0' }
    licenses { [] }
    vulnerabilities { [] }
    location do
      {
        blob_path: '/some_project/path/package_file.lock',
        path: 'package_file.lock'
      }
    end

    trait :nokogiri do
      name { 'nokogiri' }
    end

    trait :with_vulnerabilities do
      vulnerabilities do
        [{
           name: 'DDoS',
           severity: 'high',
           id: 42,
           url: 'http://gitlab.org/some-group/some-project/-/security/vulnerabilities/42'
         },
         {
           name: 'XSS vulnerability',
           severity: 'low',
           id: 1729,
           url: 'http://gitlab.org/some-group/some-project/-/security/vulnerabilities/1729'
         }]
      end
    end

    trait :with_licenses do
      licenses do
        [{
           name: 'MIT',
           url: 'http://opensource.org/licenses/mit-license'
         }]
      end
    end

    trait :indirect do
      iid { 42 }
      location do
        {
          blob_path: '/some_project/path/package_file.lock',
          path: 'package_file.lock',
          ancestors:
            [{
               name: 'dep1',
               version: '1.2'
             },
             {
               name: 'dep2',
               version: '10.11'
             }],
          top_level: false
        }
      end
    end

    trait :direct do
      iid { 24 }
      location do
        {
          blob_path: '/some_project/path/package_file.lock',
          path: 'package_file.lock',
          ancestors: nil,
          top_level: true
        }
      end
    end

    initialize_with { attributes }

    skip_create
  end
end
