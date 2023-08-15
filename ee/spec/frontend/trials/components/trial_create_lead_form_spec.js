import { GlButton, GlForm } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TrialCreateLeadForm from 'ee/trials/components/trial_create_lead_form.vue';
import { TRIAL_FORM_SUBMIT_TEXT } from 'ee/trials/constants';
import { trackSaasTrialSubmit } from '~/google_tag_manager';
import { FORM_DATA, SUBMIT_PATH } from './mock_data';

jest.mock('~/google_tag_manager', () => ({
  trackSaasTrialSubmit: jest.fn(),
}));

Vue.use(VueApollo);

describe('TrialCreateLeadForm', () => {
  let wrapper;

  const createComponent = ({ mountFunction = shallowMountExtended } = {}) => {
    return mountFunction(TrialCreateLeadForm, {
      provide: {
        submitPath: SUBMIT_PATH,
        user: FORM_DATA,
      },
    });
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findButton = () => wrapper.findComponent(GlButton);
  const findFormInput = (testId) => wrapper.findByTestId(testId);

  describe('rendering', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('has the "Continue" text on the submit button', () => {
      expect(findButton().text()).toBe(TRIAL_FORM_SUBMIT_TEXT);
    });

    it.each`
      testid            | value
      ${'first-name'}   | ${'Joe'}
      ${'last-name'}    | ${'Doe'}
      ${'company-name'} | ${'ACME'}
      ${'phone-number'} | ${'192919'}
      ${'company-size'} | ${'1-99'}
    `('has the default injected value for $testid', ({ testid, value }) => {
      expect(findFormInput(testid).attributes('value')).toBe(value);
    });

    it('has the correct form input in the form content', () => {
      const visibleFields = [
        'first-name',
        'last-name',
        'company-name',
        'company-size',
        'phone-number',
      ];

      visibleFields.forEach((f) => expect(findFormInput(f).exists()).toBe(true));
    });
  });

  describe('submitting', () => {
    beforeEach(() => {
      wrapper = createComponent({ mountFunction: mountExtended });
    });

    it('tracks the saas Trial', () => {
      findForm().trigger('submit');

      expect(trackSaasTrialSubmit).toHaveBeenCalled();
    });

    it.each`
      value                    | result
      ${null}                  | ${false}
      ${'+1 (121) 22-12-23'}   | ${false}
      ${'+12190AX '}           | ${false}
      ${'Tel:129120'}          | ${false}
      ${'11290+12'}            | ${false}
      ${FORM_DATA.phoneNumber} | ${true}
    `('validates the phone number with value of `$value`', ({ value, result }) => {
      expect(findFormInput('phone-number').exists()).toBe(true);

      findFormInput('phone-number').setValue(value);

      findForm().trigger('submit');

      expect(findFormInput('phone-number').element.checkValidity()).toBe(result);
    });
  });
});
