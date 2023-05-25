# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectTemplateExportWorker, feature_category: :groups_and_projects do
  it_behaves_like 'export worker'
end
