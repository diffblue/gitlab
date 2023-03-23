# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::UpdateBlocksService, feature_category: :code_review_workflow do
  describe '.extract_params!' do
    it 'removes and reformats merge request params' do
      mr_params = {
        unrelated: true,
        update_blocking_merge_request_refs: true,
        remove_hidden_blocking_merge_requests: true,
        blocking_merge_request_references: ['!1']
      }

      block_params = described_class.extract_params!(mr_params)

      expect(block_params).to eq(
        update: true,
        remove_hidden: true,
        references: ['!1']
      )

      expect(mr_params).to eq(unrelated: true)
    end
  end

  describe '#execute' do
    let(:merge_request) { create(:merge_request) }
    let(:user) { merge_request.target_project.first_owner }

    let_it_be(:mr_to_ignore) { create(:merge_request) }
    let_it_be(:mr_to_add) { create(:merge_request) }
    let_it_be(:mr_to_keep) { create(:merge_request) }
    let_it_be(:mr_to_del) { create(:merge_request) }
    let_it_be(:hidden_mr) { create(:merge_request) }

    let(:refs) do
      [mr_to_ignore, mr_to_add, mr_to_keep].map { |mr| mr.to_reference(full: true) }
    end

    let(:params) do
      {
        remove_hidden: remove_hidden,
        references: refs,
        update: update # rubocop: disable Rails/SaveBang
      }
    end

    subject(:service) { described_class.new(merge_request, user, params) }

    before do
      [mr_to_add, mr_to_keep, mr_to_del].each do |mr|
        mr.target_project.team.add_maintainer(user)
      end

      create(:merge_request_block, blocking_merge_request: mr_to_keep, blocked_merge_request: merge_request)
      create(:merge_request_block, blocking_merge_request: mr_to_del, blocked_merge_request: merge_request)
      create(:merge_request_block, blocking_merge_request: hidden_mr, blocked_merge_request: merge_request)
    end

    context 'licensed' do
      before do
        stub_licensed_features(blocking_merge_requests: true)
      end

      context 'with update: false' do
        let(:update) { false }
        let(:remove_hidden) { true }

        it 'does nothing' do
          expect { service.execute }.not_to change { MergeRequestBlock.count }
        end

        it_behaves_like 'does not trigger GraphQL subscription mergeRequestMergeStatusUpdated' do
          let(:action) { service.execute }
        end
      end

      context 'with update: true' do
        let(:update) { true }

        context 'with remove_hidden: false' do
          let(:remove_hidden) { false }

          it 'adds only the requested MRs the user can see' do
            service.execute

            expect(merge_request.blocking_merge_requests)
              .to contain_exactly(mr_to_add, mr_to_keep, hidden_mr)
          end

          it_behaves_like 'triggers GraphQL subscription mergeRequestMergeStatusUpdated' do
            let(:action) { service.execute }
          end

          context 'with a self-referential block' do
            let(:mr_to_add) { merge_request }

            it 'has an error on the merge request' do
              service.execute

              expect(merge_request.reload.blocking_merge_requests).not_to include(mr_to_add)
              expect(merge_request.errors[:dependencies]).to include(/Dependency chains are not supported/)
            end
          end

          context 'when an invalid reference' do
            it 'has an error on the merge request' do
              refs << 'notavalid'
              service.execute

              expect(merge_request.errors[:dependencies]).to include(/notavalid/)
            end
          end

          context 'when references did not change' do
            let(:refs) { merge_request.blocking_merge_requests.map { |mr| mr.to_reference(full: true) } }

            it 'does nothing' do
              expect { service.execute }.not_to change { MergeRequestBlock.count }
            end

            it_behaves_like 'does not trigger GraphQL subscription mergeRequestMergeStatusUpdated' do
              let(:action) { service.execute }
            end
          end

          context 'when no refs specified' do
            let(:refs) { [] }

            it 'deletes all visible blocking merge requests' do
              service.execute

              expect(merge_request.blocking_merge_requests)
                .to contain_exactly(hidden_mr)
            end

            it_behaves_like 'triggers GraphQL subscription mergeRequestMergeStatusUpdated' do
              let(:action) { service.execute }
            end
          end
        end

        context 'with remove_hidden: true' do
          let(:remove_hidden) { true }

          it_behaves_like 'triggers GraphQL subscription mergeRequestMergeStatusUpdated' do
            let(:action) { service.execute }
          end

          it 'adds visible MRs and removes the hidden MR' do
            service.execute

            expect(merge_request.blocking_merge_requests)
              .to contain_exactly(mr_to_add, mr_to_keep)
          end

          context 'when no refs specified' do
            let(:refs) { [] }

            it 'removes all blocking merge requests' do
              service.execute

              expect(merge_request.blocking_merge_requests).to be_empty
            end

            it_behaves_like 'triggers GraphQL subscription mergeRequestMergeStatusUpdated' do
              let(:action) { service.execute }
            end
          end
        end
      end
    end

    context 'unlicensed' do
      let(:update) { true }
      let(:remove_hidden) { true }

      before do
        stub_licensed_features(blocking_merge_requests: false)
      end

      it 'does nothing' do
        expect { service.execute }.not_to change { MergeRequestBlock.count }
      end

      it_behaves_like 'does not trigger GraphQL subscription mergeRequestMergeStatusUpdated' do
        let(:action) { service.execute }
      end
    end
  end
end
