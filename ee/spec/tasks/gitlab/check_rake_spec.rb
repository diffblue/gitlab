# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'EE check.rake', :silence_stdout, feature_category: :geo_replication do
  before do
    Rake.application.rake_require 'ee/lib/tasks/gitlab/check', [Rails.root.to_s]

    stub_warn_user_is_not_gitlab
  end

  describe 'gitlab:check rake task' do
    it 'runs the Geo check' do
      expect do
        run_rake_task('gitlab:geo:check')
      end.to output(/Checking Geo ... Finished/).to_stdout
    end
  end
end
