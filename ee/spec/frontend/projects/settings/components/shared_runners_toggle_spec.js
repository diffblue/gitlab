import { GlToggle } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAxiosAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import CcValidationRequiredAlert from 'ee_component/billings/components/cc_validation_required_alert.vue';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import SharedRunnersToggleComponent from '~/projects/settings/components/shared_runners_toggle.vue';

const TEST_UPDATE_PATH = '/test/update_shared_runners';

describe('projects/settings/components/shared_runners', () => {
  let wrapper;
  let mockAxios;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(SharedRunnersToggleComponent, {
      propsData: {
        isEnabled: false,
        isDisabledAndUnoverridable: false,
        isLoading: false,
        updatePath: TEST_UPDATE_PATH,
        isCreditCardValidationRequired: false,
        ...props,
      },
    });
  };

  const findSharedRunnersToggle = () => wrapper.findComponent(GlToggle);
  const findCcValidationRequiredAlert = () => wrapper.findComponent(CcValidationRequiredAlert);
  const getToggleValue = () => findSharedRunnersToggle().props('value');
  const isToggleDisabled = () => findSharedRunnersToggle().props('disabled');

  beforeEach(() => {
    mockAxios = new MockAxiosAdapter(axios);
    mockAxios.onPost(TEST_UPDATE_PATH).reply(200);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with credit card validation required and shared runners DISABLED', () => {
    beforeEach(() => {
      window.gon = {
        subscriptions_url: TEST_HOST,
        payment_form_url: TEST_HOST,
      };

      createComponent({
        isCreditCardValidationRequired: true,
        isEnabled: false,
      });
    });

    it('toggle should not be visible', () => {
      expect(findSharedRunnersToggle().exists()).toBe(false);
    });

    it('credit card validation component should exist', () => {
      expect(findCcValidationRequiredAlert().exists()).toBe(true);
      expect(findCcValidationRequiredAlert().text()).toBe(
        SharedRunnersToggleComponent.i18n.REQUIRES_VALIDATION_TEXT,
      );
    });

    it('credit card alert should be hidden after dismiss', async () => {
      findCcValidationRequiredAlert().vm.$emit('dismiss');

      await nextTick();

      expect(findCcValidationRequiredAlert().exists()).toBe(false);
    });

    describe('when credit card is validated', () => {
      beforeEach(() => {
        findCcValidationRequiredAlert().vm.$emit('verifiedCreditCard');
      });

      it('should show the toggle button', () => {
        expect(findSharedRunnersToggle().exists()).toBe(true);
        expect(getToggleValue()).toBe(false);
        expect(isToggleDisabled()).toBe(false);
      });

      it('should not show credit card alert after toggling on and off', async () => {
        findSharedRunnersToggle().vm.$emit('change', true);
        await waitForPromises();

        expect(mockAxios.history.post[0].data).toBeUndefined();
        expect(mockAxios.history.post).toHaveLength(1);
        expect(findCcValidationRequiredAlert().exists()).toBe(false);

        findSharedRunnersToggle().vm.$emit('change', false);
        await waitForPromises();

        expect(mockAxios.history.post[1].data).toBeUndefined();
        expect(mockAxios.history.post).toHaveLength(2);
        expect(findCcValidationRequiredAlert().exists()).toBe(false);
      });
    });
  });
});
