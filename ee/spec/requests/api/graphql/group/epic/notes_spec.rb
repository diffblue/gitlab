# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting notes for an epic', feature_category: :portfolio_management do
  let(:noteable) { create(:epic) }

  before do
    stub_licensed_features(epics: true)
  end

  def noteable_query(noteable_fields)
    <<~QRY
      {
        group(fullPath: "#{noteable.group.full_path}") {
          epic(iid: "#{noteable.iid}") {
            #{noteable_fields}
          }
        }
      }
    QRY
  end
  let(:noteable_data) { graphql_data['group']['epic'] }

  it_behaves_like "exposing regular notes on a noteable in GraphQL"
end
