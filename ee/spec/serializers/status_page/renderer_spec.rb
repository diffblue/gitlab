# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StatusPage::Renderer do
  describe '.markdown' do
    it 'delegates to MarkupHelper.markdown_field' do
      object = Object.new
      field = :field
      issue_iid = 1

      expect(MarkupHelper)
        .to receive(:markdown_field)
        .with(object, field, { issue_iid: issue_iid, post_process_pipeline: ::Gitlab::StatusPage::Pipeline::PostProcessPipeline })

      described_class.markdown(object, field, issue_iid: issue_iid)
    end
  end
end
