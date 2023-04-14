# frozen_string_literal: true

RSpec.shared_examples 'creates a user with ArkoseLabs risk band on signup request' do
  let(:arkose_labs_params) { { arkose_labs_token: 'arkose-labs-token' } }
  let(:params) { { user: user_attrs }.merge(arkose_labs_params) }
  let(:arkose_verification_response) do
    Gitlab::Json.parse(File.read(Rails.root.join('ee/spec/fixtures/arkose/successfully_solved_ec_response.json')))
  end

  let(:verify_response) { Arkose::VerifyResponse.new(arkose_verification_response) }
  let(:service_response) { ServiceResponse.success(payload: { response: verify_response }) }

  before do
    allow(::Arkose::Settings).to receive(:enabled_for_signup?).and_return(true)
    allow_next_instance_of(Arkose::TokenVerificationService) do |instance|
      allow(instance).to receive(:execute).and_return(service_response)
    end
  end

  subject(:create_user) { post registration_path, params: params }

  shared_examples 'creates the user' do
    it 'creates the user' do
      create_user

      created_user = User.find_by_email(user_attrs[:email])
      expect(created_user).not_to be_nil
    end
  end

  shared_examples 'renders new action with an alert flash' do
    it 'renders new action with an alert flash', :aggregate_failures do
      create_user

      expect(flash[:alert]).to include(_('Complete verification to sign up.'))
      expect(response).to render_template(:new)
    end
  end

  context 'when arkose_labs_token verification succeeds' do
    it_behaves_like 'creates the user'

    it "records the user's data from Arkose Labs" do
      expect { create_user }.to change { UserCustomAttribute.count }.from(0)
    end
  end

  context 'when verification fails' do
    let(:service_response) { ServiceResponse.error(message: 'Captcha was not solved') }

    it_behaves_like 'renders new action with an alert flash'

    it "does not record the user's data from Arkose Labs" do
      expect(Arkose::RecordUserDataService).not_to receive(:new)

      create_user
    end
  end

  context 'when user is not persisted' do
    before do
      create(:user, email: user_attrs[:email])
    end

    it "does not record the user's data from Arkose Labs" do
      expect(Arkose::RecordUserDataService).not_to receive(:new)

      # try to create a user with duplicate email
      create_user
    end
  end

  shared_examples 'skips verification and data recording' do
    it 'skips verification and data recording', :aggregate_failures do
      expect(Arkose::TokenVerificationService).not_to receive(:new)
      expect(Arkose::RecordUserDataService).not_to receive(:new)

      create_user
    end
  end

  context 'when feature is disabled' do
    before do
      allow(::Arkose::Settings).to receive(:enabled_for_signup?).and_return(false)
    end

    it_behaves_like 'creates the user'

    it_behaves_like 'skips verification and data recording'

    context 'when reCAPTCHA is enabled' do
      before do
        stub_application_setting(recaptcha_enabled: true)
      end

      it_behaves_like 'creates the user'

      context 'when reCAPTCHA verification fails' do
        before do
          allow_next_instance_of(described_class) do |controller|
            allow(controller).to receive(:verify_recaptcha).and_return(false)
          end
        end

        it 'does not create the user' do
          create_user

          expect(User.find_by(email: user_attrs[:email])).to be_nil
          expect(flash[:alert]).to eq(_('There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.'))
        end
      end
    end
  end

  context 'when arkose_labs_token param is not present' do
    let(:arkose_labs_params) { {} }

    it_behaves_like 'renders new action with an alert flash'

    it_behaves_like 'skips verification and data recording'
  end

  context 'when request is for QA' do
    before do
      allow(Gitlab::Qa).to receive(:request?).and_return(true)
    end

    it_behaves_like 'skips verification and data recording'

    it_behaves_like 'creates the user'
  end
end
