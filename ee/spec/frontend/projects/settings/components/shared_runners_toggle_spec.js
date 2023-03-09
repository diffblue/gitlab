import { GlToggle, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAxiosAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import CcValidationRequiredAlert from 'ee_component/billings/components/cc_validation_required_alert.vue';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_OK,
  HTTP_STATUS_UNAUTHORIZED,
} from '~/lib/utils/http_status';
import SharedRunnersToggleComponent from '~/projects/settings/components/shared_runners_toggle.vue';
import { CC_VALIDATION_REQUIRED_ERROR } from '~/projects/settings/constants';

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
  const findGenericAlert = () => wrapper.findComponent(GlAlert);
  const getToggleValue = () => findSharedRunnersToggle().props('value');
  const isToggleDisabled = () => findSharedRunnersToggle().props('disabled');

  beforeEach(() => {
    mockAxios = new MockAxiosAdapter(axios);
    mockAxios.onPost(TEST_UPDATE_PATH).reply(HTTP_STATUS_OK);
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

    it('should show the toggle button', () => {
      expect(findSharedRunnersToggle().exists()).toBe(true);
      expect(getToggleValue()).toBe(false);
      expect(isToggleDisabled()).toBe(false);
    });

    describe('when credit card is unvalidated', () => {
      beforeEach(() => {
        mockAxios
          .onPost(TEST_UPDATE_PATH)
          .reply(HTTP_STATUS_UNAUTHORIZED, { error: CC_VALIDATION_REQUIRED_ERROR });
      });

      it('should show credit card validation error on toggle', async () => {
        findSharedRunnersToggle().vm.$emit('change', true);
        await waitForPromises();

        expect(findCcValidationRequiredAlert().exists()).toBe(true);
        expect(findCcValidationRequiredAlert().text()).toBe(
          SharedRunnersToggleComponent.i18n.REQUIRES_VALIDATION_TEXT,
        );
      });

      it('should hide credit card alert on dismiss', async () => {
        findSharedRunnersToggle().vm.$emit('change', true);
        await waitForPromises();

        findCcValidationRequiredAlert().vm.$emit('dismiss');
        await nextTick();

        expect(findCcValidationRequiredAlert().exists()).toBe(false);
      });
    });

    describe('when credit card is validated', () => {
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

    describe('when toggling fails for some other reason', () => {
      beforeEach(() => {
        mockAxios.onPost(TEST_UPDATE_PATH).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      });

      it('should show a generic alert instead', async () => {
        findSharedRunnersToggle().vm.$emit('change', true);
        await waitForPromises();

        expect(findCcValidationRequiredAlert().exists()).toBe(false);
        expect(findGenericAlert().exists()).toBe(true);
        expect(findGenericAlert().text()).toBe(
          'An error occurred while updating the configuration.',
        );
      });
    });
  });
});
