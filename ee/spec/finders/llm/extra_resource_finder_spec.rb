# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::ExtraResourceFinder, feature_category: :ai_abstraction_layer do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:other_project) { create(:project, :repository) }
  let_it_be(:developer) { create(:user).tap { |u| project.add_developer(u) } }
  let_it_be(:other_developer) { create(:user).tap { |u| other_project.add_developer(u) } }
  let_it_be(:guest) { create(:user).tap { |u| project.add_guest(u) } }
  let_it_be(:issue) { create(:issue, project: project) }

  let(:current_user) { developer }
  let(:blob_url) { Gitlab::Routing.url_helpers.project_blob_url(project, project.default_branch) }

  describe '.execute' do
    subject(:execute) { described_class.new(current_user, referer_url).execute }

    context 'with an invalid or non-resource referer_url' do
      where(:referer_url) do
        [
          [nil],
          [''],
          ['foo'],
          [Gitlab.config.gitlab.base_url],
          [lazy { "#{blob_url}/?" }]
        ]
      end

      with_them do
        it 'returns an empty hash' do
          expect(execute).to be_empty
        end
      end
    end

    context 'when referer_url references a resource other than Blob' do
      let(:referer_url) { ::Gitlab::Routing.url_helpers.project_issue_url(project, issue.id) }

      it 'returns an empty hash' do
        expect(execute).to be_empty
      end
    end

    context 'when referer_url references a Blob' do
      let(:referer_url) { "#{blob_url}/#{path}" }

      context 'when referer_url references a valid blob' do
        let(:path) { 'files/ruby/popen.rb' }

        context 'when the blob is a readable text' do
          let(:expected_blob) { project.repository.blob_at(project.default_branch, path) }

          it 'returns the blob' do
            expect(expected_blob).not_to eq(nil)
            expect(execute[:blob].id).to eq(expected_blob.id)
          end

          context "when user is not authorized to read code for the blob's project" do
            context 'when user is a guest' do
              let(:current_user) { guest }

              it 'returns an empty hash' do
                expect(execute).to be_empty
              end
            end

            context 'when user does not have any access' do
              let(:current_user) { other_developer }

              it 'returns an empty hash' do
                expect(execute).to be_empty
              end
            end
          end
        end

        context 'when the blob is not a readable text' do
          let(:non_readable_blob) { project.repository.blob_at(project.default_branch, path) }
          let(:path) { 'Gemfile.zip' }

          it 'returns an empty hash' do
            expect(non_readable_blob).not_to eq(nil)
            expect(execute).to be_empty
          end
        end
      end

      context 'when referer_url references a non-existing blob' do
        let(:path) { 'foobar.rb' }

        it 'returns an empty hash' do
          expect(execute).to be_empty
        end
      end
    end
  end
end
