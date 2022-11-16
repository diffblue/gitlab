# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::SubscriptionsController, feature_category: :continuous_integration do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  describe 'POST create' do
    subject(:post_create) { post :create, params: { namespace_id: project.namespace, project_id: project, upstream_project_path: upstream_project.full_path } }

    let(:upstream_project) { create(:project, :public) }

    before do
      plan_limits = create(:plan_limits, :default_plan)
      plan_limits.update!(ci_project_subscriptions: 2)
    end

    context 'when user is authorized' do
      before do
        project.add_maintainer(user)
      end

      context 'when feature is available' do
        before do
          stub_licensed_features(ci_project_subscriptions: true)
        end

        context 'when user is developer in upstream project' do
          before do
            upstream_project.add_developer(user)
          end

          context 'when project is public' do
            context 'when subscription count is below the limit' do
              it 'creates a new subscription' do
                expect { post_create }.to change { project.upstream_project_subscriptions.count }.from(0).to(1)

                new_subscription = project.upstream_project_subscriptions.first
                expect(new_subscription.author).to eq(user)
              end

              it 'sets the flash' do
                post_create

                expect(controller).to set_flash[:notice].to('Subscription successfully created.')
              end

              it 'redirects to ci_cd settings' do
                post_create

                expect(response).to redirect_to project_settings_ci_cd_path(project)
              end
            end

            context 'when subscription count is above the limit' do
              before do
                create_list(:ci_subscriptions_project, 2, upstream_project: upstream_project)
              end

              it 'does not create a new subscription' do
                expect { post_create }.not_to change { project.upstream_project_subscriptions.count }.from(0)
              end

              it 'sets the flash' do
                post_create

                expect(controller).to set_flash[:alert].to(['Maximum number of ci project subscriptions (2) exceeded'])
              end

              it 'redirects to ci_cd settings' do
                post_create

                expect(response).to redirect_to project_settings_ci_cd_path(project)
              end
            end
          end

          context 'when project is not public' do
            before do
              upstream_project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
            end

            it 'does not create a new subscription' do
              expect { post_create }.not_to change { project.upstream_project_subscriptions.count }.from(0)
            end

            it 'sets the flash' do
              post_create

              expect(controller).to set_flash[:alert].to(['Upstream project needs to be public'])
            end

            it 'redirects to ci_cd settings' do
              post_create

              expect(response).to redirect_to project_settings_ci_cd_path(project)
            end
          end
        end

        context 'when user is not developer in upstream project' do
          it 'does not create a new subscription' do
            expect { post_create }.not_to change { project.upstream_project_subscriptions.count }.from(0)
          end

          it 'sets the flash' do
            post_create

            expect(controller).to set_flash[:warning].to('This project path either does not exist or you do not have access.')
          end

          it 'redirects to ci_cd settings' do
            post_create

            expect(response).to redirect_to project_settings_ci_cd_path(project)
          end
        end
      end

      context 'when feature is not available' do
        before do
          stub_licensed_features(ci_project_subscriptions: false)
        end

        it 'does not create a new subscription' do
          expect { post_create }.not_to change { project.upstream_project_subscriptions.count }.from(0)
        end

        it 'renders a not found response' do
          post_create

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when user is not authorized' do
      it 'does not create a new subscription' do
        expect { post_create }.not_to change { project.upstream_project_subscriptions.count }.from(0)
      end

      it 'renders a not found response' do
        post_create

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'DELETE destroy' do
    subject(:delete_destroy) { delete :destroy, params: { namespace_id: project.namespace, project_id: project, id: subscription.id } }

    let!(:subscription) { create(:ci_subscriptions_project, downstream_project: project) }

    context 'when user is authorized' do
      before do
        project.add_maintainer(user)
      end

      context 'when feature is available' do
        before do
          stub_licensed_features(ci_project_subscriptions: true)
        end

        it 'destroys the subscription' do
          delete_destroy

          expect { subscription.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'sets the flash' do
          delete_destroy

          expect(controller).to set_flash[:notice].to('Subscription successfully deleted.')
        end

        it 'redirects to ci_cd settings' do
          delete_destroy

          expect(response).to redirect_to project_settings_ci_cd_path(project)
        end
      end

      context 'when feature is not available' do
        before do
          stub_licensed_features(ci_project_subscriptions: false)
        end

        it 'does not destroy the subscription' do
          delete_destroy

          expect(subscription.reload).to be_persisted
        end

        it 'renders a not found reseponse' do
          delete_destroy

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when user is not authorized' do
      it 'does not destroy the subscription' do
        delete_destroy

        expect(subscription.reload).to be_persisted
      end

      it 'renders a not found response' do
        delete_destroy

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
