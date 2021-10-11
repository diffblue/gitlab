import { GlButton, GlModal } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import { sprintf } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import HandRaiseLeadButton from 'ee/hand_raise_leads/hand_raise_lead/components/hand_raise_lead_button.vue';
import { i18n } from 'ee/hand_raise_leads/hand_raise_lead/constants';
import * as SubscriptionsApi from 'ee/api/subscriptions_api';
import { formData, states, countries } from './mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('HandRaiseLeadButton', () => {
  let wrapper;
  let fakeApollo;

  const createComponent = (props = {}) => {
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
      localVue,
      apolloProvider: fakeApollo,
      propsData: {
        namespaceId: 1,
        userName: 'Joe',
        ...props,
      },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);
  const findModal = () => wrapper.findComponent(GlModal);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    fakeApollo = null;
  });

  describe('rendering', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('does not have loading icon', () => {
      expect(findButton().props('loading')).toBe(false);
    });

    it('has the "Contact sales" text on the button', () => {
      expect(findButton().text()).toBe(i18n.buttonText);
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
      expect(findModal().text()).toContain(sprintf(i18n.modalHeaderText, { userName: 'Joe' }));
      expect(findModal().text()).toContain(i18n.modalFooterText);
    });

    it('has the correct modal props', () => {
      expect(findModal().props('actionPrimary')).toStrictEqual({
        text: i18n.modalPrimary,
        attributes: [{ variant: 'success' }, { disabled: true }],
      });
      expect(findModal().props('actionCancel')).toStrictEqual({
        text: i18n.modalCancel,
      });
    });
  });

  describe('submit button', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('becomes enabled when required info is there', async () => {
      wrapper.setData({ countries, states, ...formData });

      await wrapper.vm.$nextTick();

      expect(findModal().props('actionPrimary')).toStrictEqual({
        text: i18n.modalPrimary,
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
      wrapper.setData({ countries, states, country: state });

      await wrapper.vm.$nextTick();

      expect(wrapper.findByTestId('state').exists()).toBe(display);
    });
  });

  describe('form submission', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('primary submits the valid form', async () => {
      jest.spyOn(SubscriptionsApi, 'sendHandRaiseLead').mockResolvedValue(1);

      wrapper.setData({ countries, states, country: 'US', ...formData, comment: 'comment' });

      await wrapper.vm.$nextTick();

      findModal().vm.$emit('primary');

      await wrapper.vm.$nextTick();

      expect(SubscriptionsApi.sendHandRaiseLead).toHaveBeenCalledWith({
        namespaceId: 1,
        comment: 'comment',
        ...formData,
      });

      ['firstName', 'lastName', 'companyName', 'phoneNumber'].forEach((f) =>
        expect(wrapper.vm[f]).toBe(''),
      );
      ['companySize', 'country', 'state'].forEach((f) => expect(wrapper.vm[f]).toBe(null));
    });
  });
});
