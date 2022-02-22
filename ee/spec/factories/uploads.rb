# frozen_string_literal: true

FactoryBot.modify do
  factory :upload do
    trait :issue_metric_image do
      model { association(:issuable_metric_image) }
      mount_point { :file }
      uploader { ::MetricImageUploader.name }
    end

    trait(:verification_succeeded) do
      with_file
      verification_checksum { 'abc' }
      verification_state { Upload.verification_state_value(:verification_succeeded) }
    end

    trait(:verification_failed) do
      with_file
      verification_failure { 'Could not calculate the checksum' }
      verification_state { Upload.verification_state_value(:verification_failed) }
    end

    trait(:verification_pending) do
      with_file
      verification_state { Upload.verification_state_value(:verification_pending) }
    end
  end
end
