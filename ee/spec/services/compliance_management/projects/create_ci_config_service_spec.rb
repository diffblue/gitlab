# frozen_string_literal: true

require "spec_helper"

RSpec.describe ComplianceManagement::Projects::CreateCiConfigService, feature_category: :compliance_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  subject(:service) { described_class.new(project, user) }

  before do
    project.add_developer(user)
  end

  shared_examples "service response is error" do
    it "returns error message", :aggregate_failures do
      response = subject.execute

      expect(response[:status]).to eq(error[:status])
      expect(response[:message]).to eq(error[:message])
      expect(response[:http_status]).to eq(error[:http_status] || 400)
    end
  end

  context "when project doesn't have default branch" do
    before do
      allow(project).to receive(:default_branch).and_return nil
    end

    let_it_be(:error) { { message: "Project must have default branch", status: :error, http_status: 422 } }

    it_behaves_like "service response is error"
  end

  context "when ci config is already present" do
    before do
      allow(project).to receive(:ci_config_for).with(project.default_branch).and_return true
    end

    let_it_be(:error) { { message: "Ci config already present", status: :error, http_status: 422 } }

    it_behaves_like "service response is error"
  end

  context "when branch services returns error" do
    let_it_be(:error) { { message: "Something went wrong", status: :error } }

    before do
      allow_next_instance_of(::Branches::CreateService) do |instance|
        allow(instance).to receive(:execute).and_return(error)
      end
    end

    it_behaves_like "service response is error"
  end

  context "when files create service returns error" do
    let_it_be(:error) { { message: "Something went wrong", status: :error, http_status: 422 } }

    before do
      allow_next_instance_of(::Files::CreateService) do |instance|
        allow(instance).to receive(:execute).and_return(error)
      end
    end

    it_behaves_like "service response is error"
  end

  context "when merge request is not valid" do
    let_it_be(:errors) { %w[test_error_1 test_error_2] }
    let_it_be(:error) { { message: "test_error_1 and test_error_2", status: :error, http_status: 422 } }

    before do
      allow_next_instance_of(MergeRequest) do |instance|
        allow(instance).to receive(:valid?).and_return(false)
        allow(instance.errors).to receive(:full_messages).and_return(errors)
      end
    end

    it_behaves_like "service response is error"
  end

  context "when merge request is successfully created" do
    before do
      allow(SecureRandom).to receive(:hex).and_return("12345678")
    end

    it "creates a valid merge request with correct attributes", :aggregate_failures do
      expect_next_instance_of(MergeRequest) do |instance|
        expect(instance).to receive(:valid?).exactly(3).times.and_return(true)
      end

      expect { service.execute }.to change { MergeRequest.count }.by(1)

      merge_request = MergeRequest.last

      expect(merge_request.title).to eq("Add ci config file")
      expect(merge_request.source_branch).to eq("add-ci-config-12345678")
      expect(merge_request.target_branch).to eq(project.default_branch)
    end
  end

  describe "#file_content" do
    context "when template is not present" do
      before do
        allow(Gitlab::Template::GitlabCiYmlTemplate).to receive(:find).with("Getting-Started").and_return(nil)
      end

      it "returns empty string" do
        expect(described_class.new(project, user).send(:file_content)).to eq("")
      end
    end

    context "when template is present" do
      before do
        allow_next_instance_of(Gitlab::Template::GitlabCiYmlTemplate) do |instance|
          allow(instance).to receive(:content).and_return("This is yml content")
        end
      end

      it "returns the content" do
        expect(described_class.new(project, user).send(:file_content)).to eq("This is yml content")
      end
    end
  end
end
