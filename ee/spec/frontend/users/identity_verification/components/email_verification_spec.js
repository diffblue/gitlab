import { GlForm, GlFormInput, GlButton, GlLink } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { s__ } from '~/locale';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { HTTP_STATUS_NOT_FOUND, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import EmailVerification from 'ee/users/identity_verification/components/email_verification.vue';
import {
  I18N_EMAIL_EMPTY_CODE,
  I18N_EMAIL_INVALID_CODE,
  I18N_GENERIC_ERROR,
  I18N_EMAIL_RESEND_SUCCESS,
} from 'ee/users/identity_verification/constants';

jest.mock('~/alert');

describe('EmailVerification', () => {
  let wrapper;
  let axiosMock;

  const PROVIDE = {
    email: {
      obfuscated: 'al**@g*****.com',
      verifyPath: '/users/identity_verification/verify_email_code',
      resendPath: '/users/identity_verification/resend_email_code',
    },
  };

  const createComponent = () => {
    wrapper = mount(EmailVerification, { provide: PROVIDE });
  };

  const findHeader = () => wrapper.find('p');
  const findForm = () => wrapper.findComponent(GlForm);
  const findCodeInput = () => wrapper.findComponent(GlFormInput);
  const findSubmitButton = () => wrapper.findComponent(GlButton);
  const findErrorMessage = () => wrapper.find('.invalid-feedback');
  const findResendLink = () => wrapper.findComponent(GlLink);

  const enterCode = (code) => findCodeInput().setValue(code);
  const submitForm = () => findForm().trigger('submit');

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    createComponent();
  });

  afterEach(() => {
    createAlert.mockClear();
    axiosMock.restore();
  });

  describe('rendering the form', () => {
    it('contains the obfuscated email address', () => {
      expect(findHeader().text()).toContain(PROVIDE.email.obfuscated);
    });
  });

  describe('verifying the code', () => {
    describe('when successfully verifying the code', () => {
      beforeEach(async () => {
        enterCode('123456');

        axiosMock
          .onPost(PROVIDE.email.verifyPath)
          .reply(HTTP_STATUS_OK, { status: 'success', redirect_url: 'root' });

        await submitForm();
        await axios.waitForAll();
      });

      it('emits completed event', () => {
        expect(wrapper.emitted('completed')).toHaveLength(1);
      });
    });

    describe('error messages', () => {
      it.each`
        scenario                                                         | code        | submit   | codeValid | errorShown | message
        ${'shows no error messages before submitting the form'}          | ${''}       | ${false} | ${false}  | ${false}   | ${''}
        ${'shows no error messages before submitting the form'}          | ${'xxx'}    | ${false} | ${false}  | ${false}   | ${''}
        ${'shows no error messages before submitting the form'}          | ${'123456'} | ${false} | ${true}   | ${false}   | ${''}
        ${'shows empty code error message when submitting the form'}     | ${''}       | ${true}  | ${false}  | ${true}    | ${I18N_EMAIL_EMPTY_CODE}
        ${'shows invalid error message when submitting the form'}        | ${'xxx'}    | ${true}  | ${false}  | ${true}    | ${I18N_EMAIL_INVALID_CODE}
        ${'shows incorrect code error message returned from the server'} | ${'123456'} | ${true}  | ${true}   | ${true}    | ${s__('IdentityVerification|The code is incorrect. Enter it again, or send a new code.')}
      `(`$scenario with code $code`, async ({ code, submit, codeValid, errorShown, message }) => {
        enterCode(code);

        if (submit && codeValid) {
          axiosMock
            .onPost(PROVIDE.email.verifyPath)
            .replyOnce(HTTP_STATUS_OK, { status: 'failure', message });
        }

        if (submit) {
          await submitForm();
          await axios.waitForAll();
        }

        expect(findCodeInput().classes('is-invalid')).toBe(errorShown);
        expect(findErrorMessage().exists()).toBe(errorShown);
        expect(findSubmitButton().props('disabled')).toBe(errorShown);
        if (errorShown) expect(findErrorMessage().text()).toBe(message);
      });

      it('keeps showing error messages for invalid codes after submitting the form', async () => {
        enterCode('123456');

        axiosMock
          .onPost(PROVIDE.email.verifyPath)
          .replyOnce(HTTP_STATUS_OK, { status: 'failure', message: 'error message' });

        await submitForm();
        await axios.waitForAll();

        expect(findErrorMessage().text()).toBe('error message');

        await enterCode('');
        expect(findErrorMessage().text()).toBe(I18N_EMAIL_EMPTY_CODE);

        await enterCode('xxx');
        expect(findErrorMessage().text()).toBe(I18N_EMAIL_INVALID_CODE);

        await enterCode('123456');
        expect(findErrorMessage().exists()).toBe(false);
      });

      it('captures the error and shows an alert message when the request failed', async () => {
        enterCode('123456');

        axiosMock.onPost(PROVIDE.email.verifyPath).replyOnce(HTTP_STATUS_OK, null);

        await submitForm();
        await axios.waitForAll();

        expect(createAlert).toHaveBeenCalledWith({
          message: I18N_GENERIC_ERROR,
          captureError: true,
          error: expect.any(Error),
        });
      });

      it('captures the error and shows an alert message when the request undefined', async () => {
        enterCode('123456');

        axiosMock.onPost(PROVIDE.email.verifyPath).reply(HTTP_STATUS_OK, { status: undefined });

        await submitForm();
        await axios.waitForAll();

        expect(createAlert).toHaveBeenCalledWith({
          message: I18N_GENERIC_ERROR,
          captureError: true,
          error: undefined,
        });
      });
    });
  });

  describe('resending the code', () => {
    it.each`
      scenario                                    | statusCode               | response
      ${'the code was successfully resend'}       | ${HTTP_STATUS_OK}        | ${{ status: 'success' }}
      ${'there was a problem resending the code'} | ${HTTP_STATUS_OK}        | ${{ status: 'failure', message: 'Failure sending the code' }}
      ${'when the request is undefined'}          | ${HTTP_STATUS_OK}        | ${{ status: undefined }}
      ${'when the request failed'}                | ${HTTP_STATUS_NOT_FOUND} | ${null}
    `(`shows an alert message when $scenario`, async ({ statusCode, response }) => {
      enterCode('xxx');

      await submitForm();

      axiosMock.onPost(PROVIDE.email.resendPath).replyOnce(statusCode, response);

      findResendLink().trigger('click');

      await axios.waitForAll();

      let alertObject;
      if (statusCode === HTTP_STATUS_OK && response.status === undefined) {
        alertObject = {
          captureError: true,
          error: undefined,
          message: I18N_GENERIC_ERROR,
        };
      } else if (statusCode === HTTP_STATUS_OK && response?.status === 'success') {
        alertObject = {
          message: I18N_EMAIL_RESEND_SUCCESS,
          variant: VARIANT_SUCCESS,
        };
      } else if (statusCode === HTTP_STATUS_OK && response) {
        alertObject = { message: response.message };
      } else {
        alertObject = {
          message: I18N_GENERIC_ERROR,
          captureError: true,
          error: expect.any(Error),
        };
      }
      expect(createAlert).toHaveBeenCalledWith(alertObject);

      expect(findCodeInput().element.value).toBe('');
      expect(findErrorMessage().exists()).toBe(false);
    });
  });
});
