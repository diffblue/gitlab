# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'EE-specific user routing' do
  describe 'devise_for users scope' do
    it 'defines regular and Geo routes' do
      [
        ['/users/sign_in', 'GET', 'new'],
        ['/users/auth/geo/sign_in', 'GET', 'new'],
        ['/users/sign_in', 'POST', 'create'],
        ['/users/auth/geo/sign_in', 'POST', 'create'],
        ['/users/sign_out', 'POST', 'destroy'],
        ['/users/auth/geo/sign_out', 'POST', 'destroy']
      ].each do |path, method, action|
        expect(Rails.application.routes.recognize_path(path, { method: method })).to include(
          { controller: 'sessions', action: action }
        )
      end
    end

    shared_examples 'routes session paths' do |route_type|
      it "handles #{route_type} named route helpers" do
        Rails.application.reload_routes!

        sign_in_path, sign_out_path = case route_type
                                      when :regular then
                                        ['/users/sign_in', '/users/sign_out']
                                      when :geo then
                                        ['/users/auth/geo/sign_in', '/users/auth/geo/sign_out']
                                      end

        expect(Gitlab::Routing.url_helpers.new_user_session_path).to eq(sign_in_path)
        expect(Gitlab::Routing.url_helpers.destroy_user_session_path).to eq(sign_out_path)
      end
    end

    context 'when a Geo secondary, checked without a database connection' do
      before do
        allow(Gitlab::Geo).to receive(:secondary?).with(infer_without_database: true).and_return(false)
      end

      it_behaves_like 'routes session paths', :regular
    end

    context 'Geo database is configured' do
      before do
        allow(Gitlab::Geo).to receive(:secondary?).with(infer_without_database: true).and_return(true)
      end

      it_behaves_like 'routes session paths', :geo
    end
  end
end
