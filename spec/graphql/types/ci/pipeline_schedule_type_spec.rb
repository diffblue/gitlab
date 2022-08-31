# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::PipelineScheduleType do
  include GraphqlHelpers

  specify { expect(described_class.graphql_name).to eq('PipelineSchedule') }
  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Ci::PipelineSchedules) }

  it 'exposes the expected fields' do
    expected_fields = %i[
      id
      description
      owner
      active
      lastPipeline
      refForDisplay
      refPath
      forTag
      nextRunAt
      realNextRun
      cron
      cronTimezone
      userPermissions
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
