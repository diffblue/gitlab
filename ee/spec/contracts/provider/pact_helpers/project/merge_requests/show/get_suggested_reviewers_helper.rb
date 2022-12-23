# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../../../../../spec/contracts/provider/helpers/contract_source_helper'
require_relative '../../../../states/project/merge_requests/show_state'
require_relative '../../../../../../../../spec/contracts/provider/spec_helper'
require_relative '../../../../../../../../spec/contracts/provider/environments/test'

module Provider
  module SuggestedReviewersHelper
    Pact.service_provider "GET suggested reviewers" do
      app { Environments::Test.app }

      honours_pact_with 'MergeRequests#show' do
        pact_uri Provider::ContractSourceHelper.contract_location(requester: :spec, file_path: __FILE__, edition: :ee)
      end
    end
  end
end
