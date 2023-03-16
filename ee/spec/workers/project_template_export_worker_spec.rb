# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectTemplateExportWorker, feature_category: :projects do
  it_behaves_like 'export worker'
end
