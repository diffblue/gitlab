# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupsController, type: :request, feature_category: :subgroups do
  let(:user) { create(:user) }
  let(:group) { create(:group) }

  describe 'PUT update' do
    before do
      group.add_owner(user)
      login_as(user)
    end

    subject do
      put(group_path(group), params: params)
    end

    context 'setting ip_restriction' do
      let(:params) { { group: { ip_restriction_ranges: range } } }
      let(:range) { '192.168.0.0/24' }

      before do
        stub_licensed_features(group_ip_restriction: true)
        allow_any_instance_of(Gitlab::IpRestriction::Enforcer).to(
          receive(:allows_current_ip?).and_return(true))
      end

      context 'top-level group' do
        context 'when ip_restriction does not exist' do
          context 'valid param' do
            shared_examples 'creates ip restrictions' do
              it 'creates ip restrictions' do
                expect { subject }
                  .to change { group.reload.ip_restrictions.map(&:range) }
                    .from([]).to(contain_exactly(*range.split(',')))
                expect(response).to have_gitlab_http_status(:found)
              end
            end

            context 'single IP subnet' do
              let(:range) { '192.168.0.0/24' }

              it_behaves_like 'creates ip restrictions'
            end

            context 'multiple IP subnets' do
              let(:range) { '192.168.0.0/24,192.168.0.1/8' }

              it_behaves_like 'creates ip restrictions'
            end
          end

          context 'invalid param' do
            let(:range) { 'boom!' }

            it 'adds error message' do
              expect { subject }
                .not_to(change { group.reload.ip_restrictions.count }.from(0))
              expect(response).to have_gitlab_http_status(:ok)
              expect(response.body).to include('Ip restrictions range is an invalid IP address range')
            end
          end
        end

        context 'when ip_restriction already exists' do
          let!(:ip_restriction) { IpRestriction.create!(group: group, range: '10.0.0.0/8') }
          let(:params) { { group: { ip_restriction_ranges: range } } }

          context 'ip restriction param set' do
            context 'valid param' do
              shared_examples 'updates ip restrictions' do
                it 'updates ip restrictions' do
                  expect { subject }
                    .to change { group.reload.ip_restrictions.map(&:range) }
                      .from(['10.0.0.0/8']).to(contain_exactly(*range.split(',')))
                  expect(response).to have_gitlab_http_status(:found)
                end
              end

              context 'single subnet' do
                let(:range) { '192.168.0.0/24' }

                it_behaves_like 'updates ip restrictions'
              end

              context 'multiple subnets' do
                context 'a new subnet along with the existing one' do
                  let(:range) { '10.0.0.0/8,192.168.1.0/8' }

                  it_behaves_like 'updates ip restrictions'
                end

                context 'completely new range of subnets' do
                  let(:range) { '192.168.0.0/24,192.168.1.0/8' }

                  it_behaves_like 'updates ip restrictions'
                end
              end
            end

            context 'invalid param' do
              shared_examples 'does not update existing ip restrictions' do
                it 'does not change ip restriction records' do
                  expect { subject }
                    .not_to(change { group.reload.ip_restrictions.map(&:range) }
                      .from(['10.0.0.0/8']))
                end

                it 'adds error message' do
                  subject

                  expect(response).to have_gitlab_http_status(:ok)
                  expect(response.body).to include('Ip restrictions range is an invalid IP address range')
                end
              end

              context 'not a valid subnet' do
                let(:range) { 'boom!' }

                it_behaves_like 'does not update existing ip restrictions'
              end

              context 'multiple IP subnets' do
                context 'any one of them being not a valid' do
                  let(:range) { '192.168.0.0/24,boom!' }

                  it_behaves_like 'does not update existing ip restrictions'
                end
              end
            end
          end

          context 'empty ip restriction param' do
            let(:range) { '' }

            it 'deletes ip restriction' do
              expect { subject }
                .to(change { group.reload.ip_restrictions.count }.to(0))
              expect(response).to have_gitlab_http_status(:found)
            end
          end
        end
      end

      context 'subgroup' do
        let(:group) { create(:group, :nested) }

        it 'does not create ip restriction' do
          expect { subject }
            .not_to change { group.reload.ip_restrictions.count }.from(0)
          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to include('Ip restrictions base IP subnet restriction only allowed for top-level groups')
        end
      end

      context 'with empty ip restriction param' do
        let(:params) do
          { group: { two_factor_grace_period: 42,
                     ip_restriction_ranges: "" } }
        end

        it 'updates group setting' do
          expect { subject }
            .to change { group.reload.two_factor_grace_period }.from(48).to(42)
          expect(response).to have_gitlab_http_status(:found)
        end

        it 'does not create ip restriction' do
          expect { subject }.not_to change { IpRestriction.count }
        end
      end

      context 'feature is disabled' do
        before do
          stub_licensed_features(group_ip_restriction: false)
        end

        it 'does not create ip restriction' do
          expect { subject }
            .not_to change { group.reload.ip_restrictions.count }.from(0)
          expect(response).to have_gitlab_http_status(:found)
        end
      end
    end

    context 'setting email domain restrictions' do
      let(:params) { { group: { allowed_email_domains_list: domains } } }

      before do
        stub_licensed_features(group_allowed_email_domains: true)
      end

      context 'top-level group' do
        context 'when email domain restriction does not exist' do
          context 'valid param' do
            shared_examples 'creates email domain restrictions' do
              it 'creates email domain restrictions' do
                subject

                expect(response).to have_gitlab_http_status(:found)
                expect(group.reload.allowed_email_domains.domain_names).to match_array(domains.split(","))
              end
            end

            context 'single domain' do
              let(:domains) { 'gitlab.com' }

              it_behaves_like 'creates email domain restrictions'
            end

            context 'multiple domains' do
              let(:domains) { 'gitlab.com,acme.com' }

              it_behaves_like 'creates email domain restrictions'
            end
          end

          context 'invalid param' do
            let(:domains) { 'boom!' }

            it 'adds error message' do
              expect { subject }
                .not_to(change { group.reload.allowed_email_domains.count }.from(0))
              expect(response).to have_gitlab_http_status(:ok)
              expect(response.body).to include('The domain you entered is misformatted')
            end
          end
        end

        context 'when email domain restrictions already exists' do
          let!(:allowed_email_domain) { create(:allowed_email_domain, group: group, domain: 'gitlab.com') }

          context 'allowed email domain param set' do
            context 'valid param' do
              shared_examples 'updates allowed email domain restrictions' do
                it 'updates allowed email domain restrictions' do
                  subject

                  expect(response).to have_gitlab_http_status(:found)
                  expect(group.reload.allowed_email_domains.domain_names).to match_array(domains.split(","))
                end
              end

              context 'single domain' do
                let(:domains) { 'hey.com' }

                it_behaves_like 'updates allowed email domain restrictions'
              end

              context 'multiple domains' do
                context 'a new domain along with the existing one' do
                  let(:domains) { 'gitlab.com,hey.com' }

                  it_behaves_like 'updates allowed email domain restrictions'
                end

                context 'completely new set of domains' do
                  let(:domains) { 'hey.com,google.com' }

                  it_behaves_like 'updates allowed email domain restrictions'
                end
              end
            end

            context 'invalid param' do
              shared_examples 'does not update existing email domain restrictions' do
                it 'does not change allowed_email_domains records' do
                  expect { subject }
                    .not_to(change { group.reload.allowed_email_domains.domain_names }
                      .from(['gitlab.com']))
                end

                it 'adds error message' do
                  subject

                  expect(response).to have_gitlab_http_status(:ok)
                  expect(response.body).to include('The domain you entered is misformatted')
                end
              end

              context 'not a valid domain' do
                let(:domains) { 'boom!' }

                it_behaves_like 'does not update existing email domain restrictions'
              end

              context 'multiple domains' do
                context 'any one of them being not a valid' do
                  let(:domains) { 'acme.com,boom!' }

                  it_behaves_like 'does not update existing email domain restrictions'
                end
              end
            end
          end

          context 'empty param' do
            let(:domains) { '' }

            it 'deletes all email domain restrictions' do
              expect { subject }
                .to(change { group.reload.allowed_email_domains.count }.to(0))
              expect(response).to have_gitlab_http_status(:found)
            end
          end
        end
      end

      context 'subgroup' do
        let(:group) { create(:group, :nested) }
        let(:domains) { 'gitlab.com' }

        it 'does not create email domain restriction' do
          expect { subject }
            .not_to change { group.reload.allowed_email_domains.count }.from(0)
          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to include('Allowed email domain restriction only permitted for top-level groups')
        end
      end

      context 'feature is disabled' do
        let(:domains) { 'gitlab.com' }

        before do
          stub_licensed_features(group_allowed_email_domains: false)
        end

        it 'does not create email domain restrictions' do
          expect { subject }
            .not_to change { group.reload.allowed_email_domains.count }.from(0)
          expect(response).to have_gitlab_http_status(:found)
        end
      end
    end
  end

  describe 'PUT #transfer', :saas do
    let(:new_parent_group) { create(:group) }

    before do
      group.add_owner(user)
      new_parent_group.add_owner(user)
      create(:gitlab_subscription, :ultimate, namespace: group)
      login_as(user)
    end

    it 'does not transfer a group with a gitlab saas subscription' do
      put transfer_group_path(group),
        params: { new_parent_group_id: new_parent_group.id }

      expect(response).to redirect_to(edit_group_path(group))
      expect(flash[:alert]).to include('Transfer failed')
      expect(group.reload.parent_id).to be_nil
    end

    it 'transfers a subgroup with a parent group with a gitlab saas subscription' do
      subgroup = create(:group, parent: group)

      put transfer_group_path(subgroup),
        params: { new_parent_group_id: new_parent_group.id }

      subgroup.reload
      expect(response).to redirect_to(group_path(subgroup))
      expect(flash[:alert]).to be_nil
      expect(subgroup.parent_id).to eq(new_parent_group.id)
    end
  end

  describe 'DELETE #destroy' do
    before do
      group.add_owner(user)
      login_as(user)
    end

    it 'does not delete a group with a gitlab.com subscription', :saas do
      create(:gitlab_subscription, :ultimate, namespace: group)

      Sidekiq::Testing.fake! do
        expect { delete(group_path(group)) }.not_to change(GroupDestroyWorker.jobs, :size)
        expect(response).to redirect_to(edit_group_path(group))
      end
    end

    it 'deletes a subgroup with a parent group with a gitlab.com subscription', :saas do
      create(:gitlab_subscription, :ultimate, namespace: group)
      subgroup = create(:group, parent: group)

      Sidekiq::Testing.fake! do
        expect { delete(group_path(subgroup)) }.to change(GroupDestroyWorker.jobs, :size).by(1)
        expect(response).to redirect_to(root_path)
      end
    end

    context 'delayed deletion feature is enabled' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
      end

      it 'deletes a group with trial plan', :saas do
        create(:gitlab_subscription, :ultimate_trial, trial: true, namespace: group)

        Sidekiq::Testing.fake! do
          expect { delete(group_path(group)) }.to change { group.reload.marked_for_deletion? }.from(false).to(true)
        end
      end
    end

    context 'delayed deletion feature is disabled' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: false)
      end

      it 'immediately schedules a group destroy', :saas do
        create(:gitlab_subscription, :ultimate_trial, trial: true, namespace: group)

        Sidekiq::Testing.fake! do
          expect { delete(group_path(group)) }.to change(GroupDestroyWorker.jobs, :size).by(1)
        end
      end
    end
  end
end
