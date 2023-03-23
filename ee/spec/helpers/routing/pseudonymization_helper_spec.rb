# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Routing::PseudonymizationHelper do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  before do
    stub_feature_flags(mask_page_urls: true)
    allow(helper).to receive(:group).and_return(group)
    allow(helper).to receive(:project).and_return(project)
  end

  shared_examples 'masked url' do
    it 'generates masked page url' do
      expect(helper.masked_page_url(group: group, project: project)).to eq(masked_url)
    end
  end

  describe 'when url has params to mask' do
    context 'when project/insights page is loaded' do
      let(:masked_url) { "http://localhost/namespace#{group.id}/project#{project.id}/insights" }
      let(:request) do
        double(
          :Request,
          path_parameters: {
            controller: 'projects/insights',
            action: 'show',
            namespace_id: group.name,
            project_id: project.name
          },
          protocol: 'http',
          host: 'localhost',
          query_string: '')
      end

      before do
        allow(helper).to receive(:request).and_return(request)
      end

      it_behaves_like 'masked url'
    end

    context 'when groups/insights page is loaded' do
      let(:masked_url) { "http://localhost/groups/namespace#{group.id}/-/insights" }
      let(:request) do
        double(
          :Request,
          path_parameters: {
            controller: 'groups/insights',
            action: 'show',
            group_id: group.name
          },
          protocol: 'http',
          host: 'localhost',
          query_string: '')
      end

      before do
        allow(helper).to receive(:request).and_return(request)
      end

      it_behaves_like 'masked url'
    end

    context 'when severity, sortBy, sortDesc is present' do
      let(:masked_url) { "http://localhost/namespace#{group.id}/project#{project.id}/-/security/vulnerability_report?severity=high&sortBy=reportType&sortDesc=false&state=all" }
      let(:request) do
        double(
          :Request,
          path_parameters: {
            controller: 'projects/security/vulnerability_report',
            action: 'index',
            namespace_id: group.name,
            project_id: project.name
          },
          protocol: 'http',
          host: 'localhost',
          query_string: 'severity=high&sortBy=reportType&sortDesc=false&state=all')
      end

      before do
        allow(helper).to receive(:request).and_return(request)
      end

      it_behaves_like 'masked url'
    end

    context 'when _gl, glm_content and gml_source is present' do
      let(:masked_url) { "http://localhost/namespace#{group.id}/project#{project.id}/-/security/vulnerability_report?_gl=foobar&glm_content=register&glm_source=gitlab.com" }
      let(:request) do
        double(
          :Request,
          path_parameters: {
            controller: 'projects/security/vulnerability_report',
            action: 'index',
            namespace_id: group.name,
            project_id: project.name
          },
          protocol: 'http',
          host: 'localhost',
          query_string: '_gl=foobar&glm_content=register&glm_source=gitlab.com')
      end

      before do
        allow(helper).to receive(:request).and_return(request)
      end

      it_behaves_like 'masked url'
    end

    context 'when utm_medium, utm_source, utm_campaign, utm_content and utm_budget is present' do
      let(:masked_url) do
        "http://localhost/namespace#{group.id}/project#{project.id}/-/security/vulnerability_report" \
          "?utm_budget=foobar&utm_campaign=register&utm_content=test&utm_medium=mobile&utm_source=gitlab.com"
      end

      let(:request) do
        double(
          :Request,
          path_parameters: {
            controller: 'projects/security/vulnerability_report',
            action: 'index',
            namespace_id: group.name,
            project_id: project.name
          },
          protocol: 'http',
          host: 'localhost',
          query_string: "utm_budget=foobar&utm_campaign=register" \
                        "&utm_content=test&utm_medium=mobile&utm_source=gitlab.com"
        )
      end

      before do
        allow(helper).to receive(:request).and_return(request)
      end

      it_behaves_like 'masked url'
    end
  end
end
