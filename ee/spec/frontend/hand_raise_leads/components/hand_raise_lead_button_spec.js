import { GlButton, GlModal } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { sprintf } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking } from 'helpers/tracking_helper';
import HandRaiseLeadButton from 'ee/hand_raise_leads/hand_raise_lead/components/hand_raise_lead_button.vue';
import {
  PQL_BUTTON_TEXT,
  PQL_MODAL_PRIMARY,
  PQL_MODAL_CANCEL,
  PQL_MODAL_HEADER_TEXT,
  PQL_MODAL_FOOTER_TEXT,
} from 'ee/hand_raise_leads/hand_raise_lead/constants';
import * as SubscriptionsApi from 'ee/api/subscriptions_api';
import { FORM_DATA } from './mock_data';

Vue.use(VueApollo);

describe('HandRaiseLeadButton', () => {
  let wrapper;
  let trackingSpy;

  const createComponent = (providers = {}) => {
    return shallowMountExtended(HandRaiseLeadButton, {
      provide: {
        small: false,
        user: {
          namespaceId: '1',
          userName: 'joe',
          firstName: 'Joe',
          lastName: 'Doe',
          companyName: 'ACME',
          glmContent: 'some-content',
        },
        ctaTracking: {},
        ...providers,
      },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);
  const findModal = () => wrapper.findComponent(GlModal);
  const findFormInput = (testId) => wrapper.findByTestId(testId);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('rendering', () => {
    beforeEach(() => {
      wrapper = createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    it('does not have loading icon', () => {
      expect(findButton().props('loading')).toBe(false);
    });

    it('has default medium button and the "Contact sales" text on the button', () => {
      const button = findButton();

      expect(button.props('variant')).toBe('default');
      expect(button.props('size')).toBe('medium');
      expect(button.text()).toBe(PQL_BUTTON_TEXT);
    });

    it('has the default injected values', async () => {
      const formInputValues = [
        { id: 'first-name', value: 'Joe' },
        { id: 'last-name', value: 'Doe' },
        { id: 'company-name', value: 'ACME' },
        { id: 'phone-number', value: '' },
        { id: 'company-size', value: undefined },
      ];

      formInputValues.forEach(({ id, value }) => {
        expect(findFormInput(id).attributes('value')).toBe(value);
      });

      expect(findFormInput('state').exists()).toBe(false);
    });

    it('has the correct form input in the form content', () => {
      const visibleFields = [
        'first-name',
        'last-name',
        'company-name',
        'company-size',
        'phone-number',
      ];

      visibleFields.forEach((f) => expect(wrapper.findByTestId(f).exists()).toBe(true));

      expect(wrapper.findByTestId('state').exists()).toBe(false);
    });

    it('has the correct text in the modal content', () => {
      expect(findModal().text()).toContain(sprintf(PQL_MODAL_HEADER_TEXT, { userName: 'joe' }));
      expect(findModal().text()).toContain(PQL_MODAL_FOOTER_TEXT);
    });

    it('has the correct modal props', () => {
      expect(findModal().props('actionPrimary')).toStrictEqual({
        text: PQL_MODAL_PRIMARY,
        attributes: [{ variant: 'success' }, { disabled: true }],
      });
      expect(findModal().props('actionCancel')).toStrictEqual({
        text: PQL_MODAL_CANCEL,
      });
    });

    it('tracks modal view', async () => {
      await findModal().vm.$emit('change');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'hand_raise_form_viewed', {
        label: 'hand_raise_lead_form',
      });
    });

    describe('small button', () => {
      it('has small confirm button and the "Contact sales" text on the button', () => {
        wrapper = createComponent({ small: true });
        const button = findButton();

        expect(button.props('variant')).toBe('confirm');
        expect(button.props('size')).toBe('small');
        expect(button.text()).toBe(PQL_BUTTON_TEXT);
      });
    });
  });

  describe('when provided with CTA tracking options', () => {
    const action = 'click_button';
    const label = 'contact sales';
    const experiment = 'some_experiment';

    describe('when provided with all of the CTA tracking options', () => {
      const property = 'a thing';
      const value = '123';

      beforeEach(() => {
        wrapper = createComponent({
          ctaTracking: { action, label, property, value, experiment },
        });
        trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      });

      it('sets up tracking on the CTA button', () => {
        const button = findButton();

        expect(button.attributes()).toMatchObject({
          'data-track-action': action,
          'data-track-label': label,
          'data-track-property': property,
          'data-track-value': value,
          'data-track-experiment': experiment,
        });

        button.trigger('click');

        expect(trackingSpy).toHaveBeenCalledWith('_category_', action, { label, property, value });
      });
    });

    describe('when provided with some of the CTA tracking options', () => {
      beforeEach(() => {
        wrapper = createComponent({
          ctaTracking: { action, label, experiment },
        });
        trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      });

      it('sets up tracking on the CTA button', () => {
        const button = findButton();

        expect(button.attributes()).toMatchObject({
          'data-track-action': action,
          'data-track-label': label,
          'data-track-experiment': experiment,
        });

        button.trigger('click');

        expect(trackingSpy).toHaveBeenCalledWith('_category_', action, { label });
      });
    });

    describe('when provided with none of the CTA tracking options', () => {
      beforeEach(() => {
        wrapper = createComponent();
        trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      });

      it('does not set up tracking on the CTA button', () => {
        const button = findButton();

        expect(button.attributes()).not.toMatchObject({ 'data-track-action': action });

        button.trigger('click');

        expect(trackingSpy).not.toHaveBeenCalled();
      });
    });
  });

  describe('submit button', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('becomes enabled when required info is there', async () => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({ ...FORM_DATA });

      await nextTick();

      expect(findModal().props('actionPrimary')).toStrictEqual({
        text: PQL_MODAL_PRIMARY,
        attributes: [{ variant: 'success' }, { disabled: false }],
      });
    });
  });

  describe('form', () => {
    beforeEach(async () => {
      wrapper = createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({ ...FORM_DATA, stateRequired: true, comment: 'comment' });
    });

    describe('successful submission', () => {
      beforeEach(async () => {
        jest.spyOn(SubscriptionsApi, 'sendHandRaiseLead').mockResolvedValue();

        findModal().vm.$emit('primary');
      });

      it('primary submits the valid form', async () => {
        expect(SubscriptionsApi.sendHandRaiseLead).toHaveBeenCalledWith({
          namespaceId: 1,
          comment: 'comment',
          glmContent: 'some-content',
          ...FORM_DATA,
        });
      });

      it('clears the form after submission', async () => {
        ['first-name', 'last-name', 'company-name', 'phone-number'].forEach((f) =>
          expect(wrapper.findByTestId(f).attributes('value')).toBe(''),
        );

        expect(wrapper.findByTestId('company-size').attributes('value')).toBe(undefined);
        expect(wrapper.vm.country).toBe('');
        expect(wrapper.vm.state).toBe('');
        expect(wrapper.vm.stateRequired).toBe(false);
      });

      it('tracks successful submission', async () => {
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'hand_raise_submit_form_succeeded', {
          label: 'hand_raise_lead_form',
        });
      });
    });

    describe('failed submission', () => {
      beforeEach(async () => {
        jest.spyOn(SubscriptionsApi, 'sendHandRaiseLead').mockRejectedValue();

        findModal().vm.$emit('primary');
      });

      it('tracks failed submission', async () => {
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'hand_raise_submit_form_failed', {
          label: 'hand_raise_lead_form',
        });
      });
    });

    describe('form cancel', () => {
      beforeEach(async () => {
        findModal().vm.$emit('cancel');
      });

      it('tracks failed submission', async () => {
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'hand_raise_form_canceled', {
          label: 'hand_raise_lead_form',
        });
      });
    });
  });
});
