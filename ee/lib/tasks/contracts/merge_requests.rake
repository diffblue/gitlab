# frozen_string_literal: true

return if Rails.env.production?

require 'pact/tasks/verification_task'

provider = File.expand_path('../../../spec/contracts/provider', __dir__)

namespace :contracts do
  require_relative "../../../../spec/contracts/provider/helpers/contract_source_helper"

  namespace :merge_requests do
    Pact::VerificationTask.new(:get_suggested_reviewers) do |pact|
      pact_helper_location = 'pact_helpers/project/merge_requests/show/get_suggested_reviewers_helper.rb'

      pact.uri(
        Provider::ContractSourceHelper.contract_location(
          requester: :rake,
          file_path: pact_helper_location,
          edition: :ee
        ),
        pact_helper: "#{provider}/#{pact_helper_location}"
      )
    end

    desc 'Run all merge request contract tests'
    task 'test:merge_requests', :contract_merge_requests do |_t, arg|
      errors = %w[get_suggested_reviewers].each_with_object([]) do |task, err|
        Rake::Task["contracts:merge_requests:pact:verify:#{task}"].execute
      rescue StandardError, SystemExit
        err << "contracts:merge_requests:pact:verify:#{task}"
      end

      raise StandardError, "Errors in tasks #{errors.join(', ')}" unless errors.empty?
    end
  end
end
