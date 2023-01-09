import { mountExtended } from 'helpers/vue_test_utils_helper';
import AdminEmailsForm from 'ee/admin/emails/components/admin_emails_form.vue';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

describe('AdminEmailsForm', () => {
  let wrapper;

  const defaultProvide = {
    adminEmailPath: '/admin/email',
    adminEmailsAreCurrentlyRateLimited: false,
  };

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = mountExtended(AdminEmailsForm, {
      attachTo: document.body,
      provide: { ...defaultProvide, ...provide },
    });
  };

  const findSubjectField = () => wrapper.findByLabelText(AdminEmailsForm.fields.subject.label);
  const findBodyField = () => wrapper.findByLabelText(AdminEmailsForm.fields.body.label);
  const findSubjectValidationMessage = () =>
    wrapper.findByText(AdminEmailsForm.fields.subject.validationMessage);
  const findBodyValidationMessage = () =>
    wrapper.findByText(AdminEmailsForm.fields.body.validationMessage);
  const findSubmitButton = () =>
    wrapper.findByRole('button', { name: AdminEmailsForm.i18n.submitButton });
  const clickSubmitButton = () => findSubmitButton().trigger('click');

  it('sets form `action`', () => {
    createComponent();

    expect(wrapper.attributes('action')).toBe(defaultProvide.adminEmailPath);
  });

  it('renders hidden CSRF input', () => {
    createComponent();

    expect(
      wrapper.find('input[type="hidden"][name="authenticity_token"]').attributes('value'),
    ).toBe('mock-csrf-token');
  });

  it('renders `Subject` field', () => {
    createComponent();

    expect(findSubjectField().exists()).toBe(true);
  });

  it('renders `Body` field', () => {
    createComponent();

    expect(findBodyField().exists()).toBe(true);
  });

  describe('when fields are empty', () => {
    it('renders validation messages', async () => {
      createComponent();

      await clickSubmitButton();

      expect(findSubjectValidationMessage().exists()).toBe(true);
      expect(findBodyValidationMessage().exists()).toBe(true);
    });
  });

  describe('when fields are not empty', () => {
    it('does not render validation messages', async () => {
      createComponent();

      await findSubjectField().setValue('Foo');

      await clickSubmitButton();

      expect(findSubjectValidationMessage().exists()).toBe(false);
    });
  });

  describe('when `adminEmailsAreCurrentlyRateLimited` is `true`', () => {
    it('disables submit button', () => {
      createComponent({
        provide: {
          adminEmailsAreCurrentlyRateLimited: true,
        },
      });

      expect(findSubmitButton().props('disabled')).toBe(true);
    });
  });
});
