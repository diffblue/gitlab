# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::CiSecureFileReplicator do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:model_record) { build(:ci_secure_file, project: project) }

  include_examples 'a blob replicator'
  include_examples 'a verifiable replicator'
end
