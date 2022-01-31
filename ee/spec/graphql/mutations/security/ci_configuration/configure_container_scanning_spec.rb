# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Security::CiConfiguration::ConfigureContainerScanning do
  include GraphqlHelpers

  let(:service) { ::Security::CiConfiguration::ContainerScanningCreateService }

  subject { resolve(described_class, args: { project_path: project.full_path }, ctx: { current_user: user }) }

  include_examples 'graphql mutations security ci configuration'
end
