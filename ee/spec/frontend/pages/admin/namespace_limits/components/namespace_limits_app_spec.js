import MockAdapter from 'axios-mock-adapter';
import { GlAlert } from '@gitlab/ui';
import { Wrapper } from '@vue/test-utils'; // eslint-disable-line no-unused-vars
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  APP_PLAN_LIMITS_ENDPOINT,
  APP_PLAN_LIMIT_PARAM_NAMES,
} from 'ee/pages/admin/namespace_limits/constants';
import NamespaceLimitsApp from 'ee/pages/admin/namespace_limits/components/namespace_limits_app.vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_BAD_REQUEST } from '~/lib/utils/http_status';

describe('NamespaceLimitsApp', () => {
  /** @type { Wrapper } */
  let wrapper;
  /** @type { MockAdapter } */
  let axiosMock;

  const updateFreePlanLimitsEndpoint = APP_PLAN_LIMITS_ENDPOINT.replace(':version', 'v4');
  const defaultPlanData = Object.freeze({
    notification_limit: 1,
    enforcement_limit: 2,
    storage_size_limit: 3,
  });

  const $toast = {
    show: jest.fn(),
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(NamespaceLimitsApp, { mocks: { $toast } });
  };

  const findNotificationsLimitSection = () => wrapper.findByTestId('notifications-limit-section');
  const findEnforcementLimitSection = () => wrapper.findByTestId('enforcement-limit-section');
  const findDashboardLimitSection = () => wrapper.findByTestId('dashboard-limit-section');

  beforeEach(async () => {
    window.gon = { api_version: 'v4' };
    jest.spyOn(axios, 'put');
    axiosMock = new MockAdapter(axios);
    axiosMock
      .onGet(updateFreePlanLimitsEndpoint, { params: { plan_name: 'free' } })
      .reply(HTTP_STATUS_OK, defaultPlanData);

    createComponent();
    await waitForPromises();
  });

  afterEach(() => {
    axios.put.mockReset();
    axiosMock.reset();
  });

  describe('fetching initial values', () => {
    it('will fetch and set initial values', () => {
      expect(findNotificationsLimitSection().props().limit).toBe(
        defaultPlanData.notification_limit,
      );
      expect(findEnforcementLimitSection().props().limit).toBe(defaultPlanData.enforcement_limit);
      expect(findDashboardLimitSection().props().limit).toBe(defaultPlanData.storage_size_limit);
    });

    describe('failed API response', () => {
      beforeEach(async () => {
        axiosMock.reset();
        axiosMock
          .onGet(updateFreePlanLimitsEndpoint, { params: { plan_name: 'free' } })
          .replyOnce(HTTP_STATUS_BAD_REQUEST);

        createComponent();
        await waitForPromises();
      });

      it('will display a data loading error', () => {
        const alert = wrapper.findComponent(GlAlert);
        expect(alert.exists()).toBe(true);
      });
    });
  });

  describe('notifications limit section', () => {
    it('renders namespace-limit-section component', () => {
      expect(findNotificationsLimitSection().props()).toMatchObject({
        limit: defaultPlanData.notification_limit,
        label: 'Set Notifications limit',
        description:
          'Add minimum free storage amount (in MiB) that will be used to show notifications for namespace on free plan. To remove the limit, set the value to 0 and click "Update limit" button.',
        modalBody:
          'This will limit the amount of notifications all free namespaces receives except the excluded namespaces, the limit can be removed later.',
        errorMessage: '',
      });
    });

    describe.each([
      ['0', 'Notifications limit was successfully removed'],
      ['10', 'Notifications limit was successfully added'],
    ])('setting limit to %d', (limit, toastMessage) => {
      beforeEach(async () => {
        axiosMock.onPut(updateFreePlanLimitsEndpoint).replyOnce(HTTP_STATUS_OK, defaultPlanData);
        findNotificationsLimitSection().vm.$emit('limit-change', limit);
        await waitForPromises();
      });

      it('will call relevant API endpoint', () => {
        expect(axios.put).toHaveBeenCalledWith(updateFreePlanLimitsEndpoint, undefined, {
          params: {
            plan_name: 'free',
            [APP_PLAN_LIMIT_PARAM_NAMES.notifications]: limit,
          },
        });
      });

      it('will display a success toast message', () => {
        expect($toast.show).toHaveBeenCalledWith(toastMessage);
      });
    });

    describe('failed API response on update', () => {
      it('passes the error message to the namespace-limits-section', async () => {
        axiosMock.onPut(updateFreePlanLimitsEndpoint).replyOnce(HTTP_STATUS_BAD_REQUEST, {
          message: 'There was a problem processing the request',
        });
        findNotificationsLimitSection().vm.$emit('limit-change', 41);
        await waitForPromises();

        expect(findNotificationsLimitSection().props()).toMatchObject({
          errorMessage: 'There was a problem processing the request',
        });
      });
    });
  });

  describe('enforcement limit section', () => {
    it('renders namespace-limit-section component', () => {
      expect(findEnforcementLimitSection().props()).toMatchObject({
        limit: defaultPlanData.enforcement_limit,
        label: 'Set Enforcement limit',
        description:
          'Add minimum free storage amount (in MiB) that will be used to enforce storage usage for namespaces on free plan. To remove the limit, set the value to 0 and click "Update limit" button.',
        modalBody:
          'This will change when free namespaces get storage enforcement except the excluded namespaces, the limit can be removed later.',
        errorMessage: '',
      });
    });

    describe.each([
      ['0', 'Enforcement limit was successfully removed'],
      ['10', 'Enforcement limit was successfully added'],
    ])('setting limit to %d', (limit, toastMessage) => {
      beforeEach(async () => {
        axiosMock.onPut(updateFreePlanLimitsEndpoint).replyOnce(HTTP_STATUS_OK, defaultPlanData);
        findEnforcementLimitSection().vm.$emit('limit-change', limit);
        await waitForPromises();
      });

      it('will call relevant API endpoint', () => {
        expect(axios.put).toHaveBeenCalledWith(updateFreePlanLimitsEndpoint, undefined, {
          params: {
            plan_name: 'free',
            [APP_PLAN_LIMIT_PARAM_NAMES.enforcement]: limit,
          },
        });
      });

      it('will display a success toast message', () => {
        expect($toast.show).toHaveBeenCalledWith(toastMessage);
      });
    });

    describe('failed API response on update', () => {
      it('passes the error message to the namespace-limits-section', async () => {
        axiosMock.onPut(updateFreePlanLimitsEndpoint).replyOnce(HTTP_STATUS_BAD_REQUEST, {
          message: 'There was a problem processing the request',
        });
        findEnforcementLimitSection().vm.$emit('limit-change', 41);
        await waitForPromises();

        expect(findEnforcementLimitSection().props()).toMatchObject({
          errorMessage: 'There was a problem processing the request',
        });
      });
    });
  });

  describe('dashboard limit section', () => {
    it('renders namespace-limit-section component', () => {
      expect(findDashboardLimitSection().props()).toMatchObject({
        limit: defaultPlanData.storage_size_limit,
        label: 'Set Dashboard limit',
        description:
          'Add minimum free storage amount (in MiB) that will be used to set the dashboard limit for namespaces on free plan. To remove the limit, set the value to 0 and click "Update limit" button.',
        modalBody:
          'This will change the dashboard limit for all free namespaces except the excluded namespaces, the limit can be removed later.',
        errorMessage: '',
      });
    });

    describe.each([
      ['0', 'Dashboard limit was successfully removed'],
      ['10', 'Dashboard limit was successfully added'],
    ])('setting limit to %d', (limit, toastMessage) => {
      beforeEach(async () => {
        axiosMock.onPut(updateFreePlanLimitsEndpoint).replyOnce(HTTP_STATUS_OK, defaultPlanData);
        findDashboardLimitSection().vm.$emit('limit-change', limit);
        await waitForPromises();
      });

      it('will call relevant API endpoint', () => {
        expect(axios.put).toHaveBeenCalledWith(updateFreePlanLimitsEndpoint, undefined, {
          params: {
            plan_name: 'free',
            [APP_PLAN_LIMIT_PARAM_NAMES.dashboard]: limit,
          },
        });
      });

      it('will display a success toast message', () => {
        expect($toast.show).toHaveBeenCalledWith(toastMessage);
      });
    });

    describe('failed API response on update', () => {
      it('passes the error message to the namespace-limits-section', async () => {
        axiosMock.onPut(updateFreePlanLimitsEndpoint).replyOnce(HTTP_STATUS_BAD_REQUEST, {
          message: 'There was a problem processing the request',
        });
        findDashboardLimitSection().vm.$emit('limit-change', 41);
        await waitForPromises();

        expect(findDashboardLimitSection().props()).toMatchObject({
          errorMessage: 'There was a problem processing the request',
        });
      });
    });
  });
});
