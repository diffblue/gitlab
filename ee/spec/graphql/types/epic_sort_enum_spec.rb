# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['EpicSort'] do
  it { expect(described_class.graphql_name).to eq('EpicSort') }

  it 'exposes all the existing epic sort orders' do
    expect(described_class.values.keys).to include(*%w[start_date_desc start_date_asc end_date_desc end_date_asc START_DATE_DESC START_DATE_ASC END_DATE_DESC END_DATE_ASC TITLE_DESC TITLE_ASC CREATED_AT_ASC CREATED_AT_DESC UPDATED_AT_ASC UPDATED_AT_DESC])
  end
end
