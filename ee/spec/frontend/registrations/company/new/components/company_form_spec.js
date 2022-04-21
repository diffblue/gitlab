import { GlButton, GlForm, GlFormText } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';
import { nextTick } from 'vue';
import RegistrationForm from 'ee/registrations/components/company_form.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { TRIAL_FORM_SUBMIT_TEXT } from 'ee/trials/constants';
import RegistrationTrialToggle from 'ee/registrations/components/registration_trial_toggle.vue';

const localVue = createLocalVue();

const SUBMIT_PATH = '_submit_path_';

describe('RegistrationForm', () => {
  let wrapper;

  const createComponent = ({ mountFunction = shallowMountExtended } = {}) => {
    return mountFunction(RegistrationForm, {
      localVue,
      provide: {
        submitPath: SUBMIT_PATH,
      },
      propsData: { trial: true },
    });
  };

  const findDescription = () => wrapper.findComponent(GlFormText);
  const findButton = () => wrapper.findComponent(GlButton);
  const findForm = () => wrapper.findComponent(GlForm);
  const findFormInput = (testId) => wrapper.findByTestId(testId);

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('rendering', () => {
    it.each`
      trialBool | descriptionText
      ${true}   | ${'To activate your trial, we need additional details from you.'}
      ${false}  | ${'To complete registration, we need additional details from you.'}
    `('displays the correct page description text', async ({ trialBool, descriptionText }) => {
      wrapper.setProps({ trial: trialBool });
      await nextTick();

      expect(findDescription().text()).toContain(descriptionText);
    });

    it('has the "Continue" text on the submit button', () => {
      expect(findButton().text()).toBe(TRIAL_FORM_SUBMIT_TEXT);
    });

    it('sets the trial value to be true', () => {
      expect(wrapper.props().trial).toBe(true);
      expect(wrapper.findComponent(RegistrationTrialToggle).props('active')).toBe(true);
    });

    it.each`
      testid
      ${'company_name'}
      ${'company_size'}
      ${'country'}
      ${'phone_number'}
      ${'website_url'}
      ${'trial'}
    `('has the correct form input in the form content', ({ testid }) => {
      expect(findFormInput(testid).exists()).toBe(true);
    });
  });

  describe('submitting', () => {
    it('submits the form when button is clicked', () => {
      expect(findButton().attributes('type')).toBe('submit');
    });

    it('displays form with correct action', () => {
      expect(findForm().attributes('action')).toBe(SUBMIT_PATH);
    });
  });
});
