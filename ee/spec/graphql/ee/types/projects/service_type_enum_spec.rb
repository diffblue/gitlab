# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ServiceType'] do
  context 'GitLabSlackApplicationService' do
    subject { described_class.values['GITLAB_SLACK_APPLICATION_SERVICE'] }

    it 'appends a note to the description' do
      expect(subject.description).to end_with(' (Gitlab.com only)')
    end
  end
end
