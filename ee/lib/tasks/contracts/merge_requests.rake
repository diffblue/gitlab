# frozen_string_literal: true

return if Rails.env.production?

require 'pact/tasks/verification_task'

contracts = File.expand_path('../../../spec/contracts/contracts/project/merge_request', __dir__)
provider = File.expand_path('../../../spec/contracts/provider', __dir__)

namespace :contracts do
  namespace :merge_requests do
    Pact::VerificationTask.new(:suggested_reviewers) do |pact|
      pact.uri(
        "#{contracts}/show/mergerequest#show-merge_request_suggested_reviewers_endpoint.json",
        pact_helper: "#{provider}/pact_helpers/project/merge_request/show/suggested_reviewers_helper.rb"
      )
    end

    desc 'Run all merge request contract tests'
    task 'test:merge_requests', :contract_merge_requests do |_t, arg|
      errors = %w[suggested_reviewers].each_with_object([]) do |task, err|
        Rake::Task["contracts:merge_requests:pact:verify:#{task}"].execute
      rescue StandardError, SystemExit
        err << "contracts:merge_requests:pact:verify:#{task}"
      end

      raise StandardError, "Errors in tasks #{errors.join(', ')}" unless errors.empty?
    end
  end
end
