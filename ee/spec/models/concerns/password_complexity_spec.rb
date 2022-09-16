# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PasswordComplexity do
  describe 'validations' do
    let(:password) { User.random_password }
    let(:user) { build(:user, password: password) }

    shared_examples_for 'validating different types of password combination' do
      it 'shows that any combinations is valid' do
        user.password = '81668366'
        expect(user).to be_valid

        user.password = 'ysspqyst'
        expect(user).to be_valid

        user.password = 'YSSPQYST'
        expect(user).to be_valid

        user.password = '!@#$%^&*()'
        expect(user).to be_valid

        user.password = '1aA$%^&*()'
        expect(user).to be_valid
      end
    end

    context 'when password_complexity feature is not available' do
      it_behaves_like 'validating different types of password combination'
    end

    context 'when password_complexity feature is available' do
      before do
        stub_licensed_features(password_complexity: true)
      end

      context 'when no rules are enabled' do
        it_behaves_like 'validating different types of password combination'
      end

      context 'when number is required' do
        before do
          stub_application_setting(password_number_required: true)
        end

        context 'without any number in password' do
          let(:password) { 'ysspqyst' }

          it 'is not valid' do
            expect(user).not_to be_valid
          end
        end

        context 'with a number in password' do
          let(:password) { 'ysspqyst1' }

          it 'is valid' do
            expect(user).to be_valid
          end
        end

        context 'with an unicode Nd number in password' do
          let(:password) { 'ysspqyst๑' }

          it 'is valid' do
            expect(user).to be_valid
          end
        end
      end

      context 'when uppercase letter is required' do
        before do
          stub_application_setting(password_uppercase_required: true)
        end

        context 'without any uppercase letter' do
          let(:password) { '8166836a' }

          it 'is not valid' do
            expect(user).not_to be_valid
          end
        end

        context 'with a uppercase letter' do
          let(:password) { '8166836A' }

          it 'is valid' do
            expect(user).to be_valid
          end
        end

        context 'with a uppercase accented letter' do
          let(:password) { '8166836Á' }

          it 'is valid' do
            expect(user).to be_valid
          end
        end
      end

      context 'when password complexity requires all types' do
        before do
          stub_application_setting(password_number_required: true)
          stub_application_setting(password_symbol_required: true)
          stub_application_setting(password_lowercase_required: true)
          stub_application_setting(password_uppercase_required: true)
        end

        context 'when password complexity rules are not fully matched' do
          let(:password) { 'qwertasdf' }

          it 'is not valid' do
            expect(user).not_to be_valid
            expect(user.errors[:password]).to include(s_('Password|requires at least one number'))
            expect(user.errors[:password]).to include(s_('Password|requires at least one uppercase letter'))
            expect(user.errors[:password]).to include(s_('Password|requires at least one symbol character'))

            user.password = 'QWERAS,1'
            expect(user).not_to be_valid
            expect(user.errors[:password]).to include(s_('Password|requires at least one lowercase letter'))
          end
        end

        context 'when password complexity rules are fully matched' do
          let(:password) { 'áA,12345' }

          it 'is valid' do
            expect(user).to be_valid
          end
        end

        context 'when updating user attributes' do
          # Password is set on User objects created by factory
          # Use .find to load it from the database
          let!(:user) { User.find(create(:user, password: password).id) }
          let(:first_name) { FFaker::Name.first_name }

          context 'when password is not updated' do
            it 'does not check password complexity' do
              user.first_name = first_name

              expect(user.password).to be_nil
              expect(user).to be_valid
            end
          end

          context 'when password is updated' do
            it 'checks password complexity' do
              user.password = '81668366'

              expect(user).not_to be_valid
            end
          end
        end
      end
    end
  end
end
