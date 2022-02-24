# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::UserPermissionExportsController do
  let_it_be(:admin) { create(:admin) }

  subject { get admin_user_permission_exports_path }

  before do
    allow(admin).to receive(:can?).and_call_original
    allow(admin).to receive(:can?).with(:export_user_permissions).and_return(authorized)
    sign_in(admin)
  end

  describe '#index', :enable_admin_mode do
    context 'when authorized' do
      let(:authorized) { true }

      it 'redirects back to admin users list with notice' do
        subject

        expect(response).to redirect_to(admin_users_path)
        expect(flash[:success]).to eq('Report is generating and will be sent to your email address.')
      end

      it 'enqueues a job to generate the CSV file' do
        expect { subject }.to have_enqueued_mail(::Admin::MembershipsMailer, :instance_memberships_export)
      end
    end

    context 'when user is unauthorised' do
      let(:authorized) { false }

      it 'responds with :not_found' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
