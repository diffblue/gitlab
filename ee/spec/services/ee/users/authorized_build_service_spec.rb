# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::AuthorizedBuildService do
  describe '#execute' do
    context 'with non admin user' do
      let(:non_admin) { create(:user) }

      context 'when user signup cap is set' do
        before do
          allow(Gitlab::CurrentSettings).to receive(:new_user_signups_cap).and_return(10)
        end

        it 'does not set the user state to blocked_pending_approval for non human users' do
          params = {
            name: 'Project Bot',
            email: 'project_bot@example.com',
            username: 'project_bot',
            user_type: 'project_bot'
          }

          service = described_class.new(non_admin, params)
          user = service.execute

          expect(user).to be_active
        end
      end
    end

    context 'with a nil user' do
      let(:service) { described_class.new(nil, params) }
      let(:params) do
        { name: 'John Doe', username: 'jduser', email: 'jd@example.com', password: 'mydummypass' }
      end

      shared_examples 'unsuccessful user domain matching' do
        it 'creates an unconfirmed user' do
          user = service.execute

          expect(user).to be_present
          expect(user).not_to be_confirmed
        end
      end

      shared_examples 'successful user domain matching' do
        it 'creates a confirmed user' do
          user = service.execute

          expect(user).to be_present
          expect(user).to be_confirmed
        end
      end

      context 'when email confirmation setting is set to `hard`' do
        before do
          stub_application_setting_enum('email_confirmation_setting', 'hard')
        end

        it_behaves_like 'unsuccessful user domain matching'

        context 'with a group_id param' do
          let(:group) { create(:group) }

          before do
            params[:group_id] = group.id
          end

          it_behaves_like 'unsuccessful user domain matching'

          context 'when domain verification is available', :saas do
            before do
              stub_licensed_features(domain_verification: true)
            end

            context 'when a matching verified domain is present in the group hierarchy' do
              before do
                project = create(:project, group: group)
                create(:pages_domain, project: project, domain: 'example.com')
              end

              using RSpec::Parameterized::TableSyntax

              where(:provider, :expect_confirmed?) do
                ::Users::BuildService::GROUP_SAML_PROVIDER  | true
                ::Users::BuildService::GROUP_SCIM_PROVIDER  | true
                'google_oauth2'                             | false
              end

              with_them do
                it 'creates a user with proper confirmation' do
                  params[:provider] = provider

                  user = service.execute

                  expect(user).to be_present
                  expect(user.confirmed?).to eq(expect_confirmed?)
                end
              end

              context 'with various email address formats' do
                before do
                  params[:provider] = ::Users::BuildService::GROUP_SAML_PROVIDER
                end

                context 'when email domain case varies' do
                  before do
                    params[:email] = 'jdoe@EXample.com'
                  end

                  it_behaves_like 'successful user domain matching'
                end

                context 'when the email address is invalid' do
                  before do
                    params[:email] = 'jdoe@jdoe@example.com'
                  end

                  it_behaves_like 'unsuccessful user domain matching'
                end
              end
            end

            context 'when no verified domains exist' do
              before do
                project = create(:project, group: group)
                create(:pages_domain, :unverified, project: project, domain: 'example.com')
                params[:provider] = ::Users::BuildService::GROUP_SAML_PROVIDER
              end

              it_behaves_like 'unsuccessful user domain matching'
            end
          end
        end
      end
    end
  end
end
