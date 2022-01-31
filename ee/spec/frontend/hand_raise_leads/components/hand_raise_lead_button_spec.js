import { GlButton, GlModal } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { sprintf } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
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
import { formData, states, countries } from './mock_data';

Vue.use(VueApollo);

describe('HandRaiseLeadButton', () => {
  let wrapper;
  let fakeApollo;
  let trackingSpy;

  const createComponent = (small = false) => {
    const mockResolvers = {
      Query: {
        countries() {
          return [{ id: 'US', name: 'United States' }];
        },
        states() {
          return [{ countryId: 'US', id: 'CA', name: 'California' }];
        },
      },
    };
    fakeApollo = createMockApollo([], mockResolvers);

    return shallowMountExtended(HandRaiseLeadButton, {
      apolloProvider: fakeApollo,
      provide: {
        small,
        user: {
          namespaceId: '1',
          userName: 'joe',
          firstName: 'Joe',
          lastName: 'Doe',
          companyName: 'ACME',
          glmContent: 'some-content',
        },
      },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);
  const findModal = () => wrapper.findComponent(GlModal);
  const findFormInput = (testId) => wrapper.findByTestId(testId);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    fakeApollo = null;
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
        { id: 'country', value: undefined },
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
        'country',
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
        wrapper = createComponent(true);
        const button = findButton();

        expect(button.props('variant')).toBe('confirm');
        expect(button.props('size')).toBe('small');
        expect(button.text()).toBe(PQL_BUTTON_TEXT);
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
      wrapper.setData({ countries, states, ...formData });

      await nextTick();

      expect(findModal().props('actionPrimary')).toStrictEqual({
        text: PQL_MODAL_PRIMARY,
        attributes: [{ variant: 'success' }, { disabled: false }],
      });
    });
  });

  describe('country & state handling', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it.each`
      state   | display
      ${'US'} | ${true}
      ${'CA'} | ${true}
      ${'NL'} | ${false}
    `('displayed $display', async ({ state, display }) => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({ countries, states, country: state });

      await nextTick();

      expect(wrapper.findByTestId('state').exists()).toBe(display);
    });
  });

  describe('form', () => {
    beforeEach(async () => {
      wrapper = createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({ countries, states, country: 'US', ...formData, comment: 'comment' });
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
          ...formData,
        });
      });

      it('clears the form after submission', async () => {
        ['first-name', 'last-name', 'company-name', 'phone-number'].forEach((f) =>
          expect(wrapper.findByTestId(f).attributes('value')).toBe(''),
        );

        ['company-size', 'country'].forEach((f) =>
          expect(wrapper.findByTestId(f).attributes('value')).toBe(undefined),
        );

        expect(wrapper.findByTestId('state').exists()).toBe(false);
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
