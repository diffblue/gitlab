# frozen_string_literal: true

RSpec.shared_examples DescriptionDiffActions do
  let(:base_params) { { namespace_id: project.namespace, project_id: project, id: issuable } }

  describe do
    let_it_be(:version_1) { create(:description_version, issuable.class.name.underscore => issuable) }
    let_it_be(:version_2) { create(:description_version, issuable.class.name.underscore => issuable) }
    let_it_be(:version_3) { create(:description_version, issuable.class.name.underscore => issuable) }

    def get_description_diff(extra_params = {})
      get :description_diff, params: base_params.merge(extra_params)
    end

    def delete_description_version(extra_params = {})
      delete :delete_description_version, params: base_params.merge(extra_params)
    end

    shared_examples 'description diff actions' do
      context 'GET description_diff' do
        it 'returns the diff with the previous version' do
          expect(Gitlab::Diff::CharDiff).to receive(:new).with(version_2.description, version_3.description).and_call_original

          get_description_diff(version_id: version_3)

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'returns the diff with the previous version of the specified start_version_id' do
          expect(Gitlab::Diff::CharDiff).to receive(:new).with(version_1.description, version_3.description).and_call_original

          get_description_diff(version_id: version_3, start_version_id: version_2)

          expect(response).to have_gitlab_http_status(:ok)
        end

        context 'when description version is from another issuable' do
          it 'returns 404' do
            other_version = create(:description_version)

            get_description_diff(version_id: other_version)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when start_version_id is from another issuable' do
          it 'returns 404' do
            other_version = create(:description_version)

            get_description_diff(version_id: version_3, start_version_id: other_version)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when start_version_id is deleted' do
          it 'returns 404' do
            version_2.delete!

            get_description_diff(version_id: version_3, start_version_id: version_2)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when description version is deleted' do
          it 'returns 404' do
            version_3.delete!

            delete_description_version(version_id: version_3)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'DELETE description_diff' do
        before do
          developer_user = create(:user)
          issuable.resource_parent.add_developer(developer_user)
          sign_in(developer_user)
        end

        it 'returns 200' do
          delete_description_version(version_id: version_3)

          expect(response).to have_gitlab_http_status(:ok)
          expect(version_3.reload.deleted_at).to be_present
        end

        context 'when start_version_id is present' do
          it 'returns 200' do
            delete_description_version(version_id: version_3, start_version_id: version_1)

            expect(response).to have_gitlab_http_status(:ok)
            expect(version_1.reload.deleted_at).to be_present
            expect(version_2.reload.deleted_at).to be_present
            expect(version_3.reload.deleted_at).to be_present
          end
        end

        context 'when version is already deleted' do
          it 'returns 404' do
            version_3.delete!

            delete_description_version(version_id: version_3)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when user cannot admin issuable' do
          it 'returns 404' do
            guest_user = create(:user)
            issuable.resource_parent.add_guest(guest_user)
            sign_in(guest_user)

            delete_description_version(version_id: version_3)

            expect(response).to have_gitlab_http_status(:not_found)
            expect(version_3.reload.deleted_at).to be_nil
          end
        end
      end
    end

    context 'when license is available' do
      before do
        stub_licensed_features(epics: true, description_diffs: true)
      end

      it_behaves_like 'description diff actions'
    end

    context 'when features are available through Registration Features' do
      before do
        stub_application_setting(usage_ping_features_enabled: true)
        stub_licensed_features(epics: true, description_diffs: false)
      end

      it_behaves_like 'description diff actions'
    end

    context 'when license is not available' do
      before do
        stub_licensed_features(epics: true, description_diffs: false)
      end

      context 'GET description_diff' do
        it 'returns 404' do
          get_description_diff(version_id: version_3)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'DELETE description_diff' do
        it 'returns 404' do
          delete_description_version(version_id: version_3)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
