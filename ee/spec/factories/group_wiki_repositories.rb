# frozen_string_literal: true

FactoryBot.define do
  factory :group_wiki_repository do
    group

    after(:build) do |group_wiki_repository, _|
      group_wiki_repository.shard_name = group_wiki_repository.repository_storage
      group_wiki_repository.disk_path  = group_wiki_repository.group.wiki.storage.disk_path
    end

    trait :verification_succeeded do
      verification_checksum { 'abc' }
      verification_state { GroupWikiRepository.verification_state_value(:verification_succeeded) }
    end

    trait :verification_failed do
      verification_failure { 'Could not calculate the checksum' }
      verification_state { GroupWikiRepository.verification_state_value(:verification_failed) }
    end
  end
end
