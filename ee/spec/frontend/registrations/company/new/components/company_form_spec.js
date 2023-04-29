import { GlButton, GlForm, GlFormText, GlToggle } from '@gitlab/ui';
import { nextTick } from 'vue';
import RegistrationForm from 'ee/registrations/components/company_form.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking } from 'helpers/tracking_helper';
import {
  TRIAL_FORM_SUBMIT_TEXT,
  AUTOMATIC_TRIAL_DESCRIPTION,
  AUTOMATIC_TRIAL_FORM_SUBMIT_TEXT,
} from 'ee/trials/constants';
import { stubExperiments } from 'helpers/experimentation_helper';

const SUBMIT_PATH = '_submit_path_';

describe('RegistrationForm', () => {
  let wrapper;

  const createComponent = ({ mountFunction = shallowMountExtended, propsData } = {}) => {
    return mountFunction(RegistrationForm, {
      provide: {
        submitPath: SUBMIT_PATH,
      },
      propsData: {
        ...propsData,
      },
    });
  };

  const findDescription = () => wrapper.findComponent(GlFormText);
  const findButton = () => wrapper.findComponent(GlButton);
  const findForm = () => wrapper.findComponent(GlForm);
  const findFormInput = (testId) => wrapper.findByTestId(testId);
  const findToggle = () => wrapper.findComponent(GlToggle);
  const findAutomaticTrialDescriptionText = () =>
    wrapper.findByTestId('automatic_trial_description_text');

  describe('when trial is true', () => {
    beforeEach(() => {
      wrapper = createComponent({ propsData: { trial: true } });
    });

    it('sets the trial value to be true', () => {
      expect(wrapper.props().trial).toBe(true);
    });

    it('hides trial toggle', () => {
      expect(findToggle()).not.toBeVisible();
    });
  });

  describe('when trial is false', () => {
    beforeEach(() => {
      wrapper = createComponent({ propsData: { trial: false } });
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

      it('trial value should be set to false', () => {
        expect(wrapper.props().trial).toBe(false);
        expect(findToggle().props('value')).toBe(false);
      });

      it.each`
        testid
        ${'company_name'}
        ${'company_size'}
        ${'country'}
        ${'phone_number'}
        ${'website_url'}
        ${'trial_onboarding_flow'}
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

    describe('with snowplow tracking', () => {
      it('tracks trial toggle is enabled', () => {
        const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

        findToggle().vm.$emit('change', true);

        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_trial_toggle', {
          label: 'ON',
        });
      });

      it('tracks trial toggle is disabled', () => {
        const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

        findToggle().vm.$emit('change', false);

        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_trial_toggle', {
          label: 'OFF',
        });
      });
    });
  });

  describe('when automatic_trial_registration experiment is control', () => {
    beforeEach(() => {
      wrapper = createComponent({ propsData: { automaticTrial: false } });
      stubExperiments({ automatic_trial_registration: 'control' });
    });

    const trackingExperimentContext = {
      data: {
        experiment: 'automatic_trial_registration',
        variant: 'control',
      },
      schema: 'iglu:com.gitlab/gitlab_experiment/jsonschema/1-0-0',
    };

    it('shows trial toggle', () => {
      expect(findToggle().isVisible()).toBe(true);
    });

    it('does not display automaticTrialDescription text', () => {
      expect(findAutomaticTrialDescriptionText().exists()).toBe(false);
    });

    it('tracks trial toggle is enabled with experiment context', () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

      findToggle().vm.$emit('change', true);

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_trial_toggle', {
        label: 'ON',
        context: trackingExperimentContext,
      });
    });

    it('tracks trial toggle is disabled with experiment context', () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

      findToggle().vm.$emit('change', false);

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_trial_toggle', {
        label: 'OFF',
        context: trackingExperimentContext,
      });
    });
  });

  describe('when automatic_trial_registration experiment is candidate', () => {
    beforeEach(() => {
      wrapper = createComponent({ propsData: { automaticTrial: true } });
    });

    it('hides trial toggle', () => {
      expect(findToggle().isVisible()).toBe(false);
    });

    it('displays automaticTrialFormSubmitText on submit button', () => {
      expect(findButton().text()).toBe(AUTOMATIC_TRIAL_FORM_SUBMIT_TEXT);
    });

    it('displays automaticTrialDescription text', () => {
      expect(findAutomaticTrialDescriptionText().exists()).toBe(true);
      expect(findAutomaticTrialDescriptionText().text()).toBe(AUTOMATIC_TRIAL_DESCRIPTION);
    });
  });
});
