import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  UPDATE_FREE_PLAN_LIMITS_ENDPOINT,
  UPDATE_PLAN_LIMIT_PARAM_NAMES,
} from 'ee/pages/admin/namespace_limits/constants';
import NamespaceLimitsApp from 'ee/pages/admin/namespace_limits/components/namespace_limits_app.vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_BAD_REQUEST } from '~/lib/utils/http_status';

describe('NamespaceLimitsApp', () => {
  let wrapper;
  let axiosMock;

  const updateFreePlanLimitsEndpoint = UPDATE_FREE_PLAN_LIMITS_ENDPOINT.replace(':version', 'v4');

  const $toast = {
    show: jest.fn(),
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(NamespaceLimitsApp, { mocks: { $toast } });
  };

  const findNotificationsLimitSection = () => wrapper.findByTestId('notifications-limit-section');
  const findEnforcementLimitSection = () => wrapper.findByTestId('enforcement-limit-section');
  const findDashboardLimitSection = () => wrapper.findByTestId('dashboard-limit-section');

  describe('notifications limit section', () => {
    beforeEach(() => {
      window.gon = { api_version: 'v4' };
      axiosMock = new MockAdapter(axios);
    });

    afterEach(() => {
      axiosMock.restore();
    });

    it('renders namespace-limit-section component', () => {
      createComponent();

      expect(findNotificationsLimitSection().props()).toMatchObject({
        label: 'Set Notifications limit',
        description:
          'Add minimum free storage amount (in MiB) that will be used to show notifications for namespace on free plan. To remove the limit, set the value to 0 and click "Update limit" button.',
        modalBody:
          'This will limit the amount of notifications all free namespaces receives except the excluded namespaces, the limit can be removed later.',
        errorMessage: '',
      });
    });

    describe('successful API response', () => {
      it.each([
        ['0', 'Notifications limit was successfully removed'],
        ['10', 'Notifications limit was successfully added'],
      ])('shows correct toast when limit is %d', async (limit, toastMessage) => {
        axiosMock
          .onPut(
            `${updateFreePlanLimitsEndpoint}&${UPDATE_PLAN_LIMIT_PARAM_NAMES.notifications}=${limit}`,
          )
          .replyOnce(HTTP_STATUS_OK);
        createComponent();
        findNotificationsLimitSection().vm.$emit('limit-change', limit);
        await waitForPromises();
        expect($toast.show).toHaveBeenCalledWith(toastMessage);
      });
    });

    describe('failed API response', () => {
      beforeEach(() => {
        const limit = 1;
        axiosMock
          .onPut(
            `${updateFreePlanLimitsEndpoint}&${UPDATE_PLAN_LIMIT_PARAM_NAMES.notifications}=${limit}`,
          )
          .replyOnce(HTTP_STATUS_BAD_REQUEST, {
            message: 'There was a problem processing the request',
          });
        createComponent();
        findNotificationsLimitSection().vm.$emit('limit-change', limit);
        return waitForPromises();
      });

      it('passes the error message to the namespace-limits-section', () => {
        expect(findNotificationsLimitSection().props()).toMatchObject({
          errorMessage: 'There was a problem processing the request',
        });
      });
    });
  });

  describe('enforcement limit section', () => {
    beforeEach(() => {
      window.gon = { api_version: 'v4' };
      axiosMock = new MockAdapter(axios);
    });

    afterEach(() => {
      axiosMock.restore();
    });

    it('renders namespace-limit-section component', () => {
      createComponent();

      expect(findEnforcementLimitSection().props()).toMatchObject({
        label: 'Set Enforcement limit',
        description:
          'Add minimum free storage amount (in MiB) that will be used to enforce storage usage for namespaces on free plan. To remove the limit, set the value to 0 and click "Update limit" button.',
        modalBody:
          'This will change when free namespaces get storage enforcement except the excluded namespaces, the limit can be removed later.',
        errorMessage: '',
      });
    });

    describe('successful API response', () => {
      it.each([
        ['0', 'Enforcement limit was successfully removed'],
        ['10', 'Enforcement limit was successfully added'],
      ])('shows correct toast when limit is %d', async (limit, toastMessage) => {
        axiosMock
          .onPut(
            `${updateFreePlanLimitsEndpoint}&${UPDATE_PLAN_LIMIT_PARAM_NAMES.enforcement}=${limit}`,
          )
          .replyOnce(HTTP_STATUS_OK);
        createComponent();
        findEnforcementLimitSection().vm.$emit('limit-change', limit);
        await waitForPromises();
        expect($toast.show).toHaveBeenCalledWith(toastMessage);
      });
    });

    describe('failed API response', () => {
      beforeEach(() => {
        const limit = 1;
        axiosMock
          .onPut(
            `${updateFreePlanLimitsEndpoint}&${UPDATE_PLAN_LIMIT_PARAM_NAMES.enforcement}=${limit}`,
          )
          .replyOnce(HTTP_STATUS_BAD_REQUEST, {
            message: 'There was a problem processing the request',
          });
        createComponent();
        findEnforcementLimitSection().vm.$emit('limit-change', limit);
        return waitForPromises();
      });

      it('passes the error message to the namespace-limits-section', () => {
        expect(findEnforcementLimitSection().props()).toMatchObject({
          errorMessage: 'There was a problem processing the request',
        });
      });
    });
  });

  describe('dashboard limit section', () => {
    beforeEach(() => {
      window.gon = { api_version: 'v4' };
      axiosMock = new MockAdapter(axios);
    });

    afterEach(() => {
      axiosMock.restore();
    });

    it('renders namespace-limit-section component', () => {
      createComponent();

      expect(findDashboardLimitSection().props()).toMatchObject({
        label: 'Set Dashboard limit',
        description:
          'Add minimum free storage amount (in MiB) that will be used to set the dashboard limit for namespaces on free plan. To remove the limit, set the value to 0 and click "Update limit" button.',
        modalBody:
          'This will change the dashboard limit for all free namespaces except the excluded namespaces, the limit can be removed later.',
        errorMessage: '',
      });
    });

    describe('successful API response', () => {
      it.each([
        ['0', 'Dashboard limit was successfully removed'],
        ['10', 'Dashboard limit was successfully added'],
      ])('shows correct toast when limit is %d', async (limit, toastMessage) => {
        axiosMock
          .onPut(
            `${updateFreePlanLimitsEndpoint}&${UPDATE_PLAN_LIMIT_PARAM_NAMES.dashboard}=${limit}`,
          )
          .replyOnce(HTTP_STATUS_OK);
        createComponent();
        findDashboardLimitSection().vm.$emit('limit-change', limit);
        await waitForPromises();
        expect($toast.show).toHaveBeenCalledWith(toastMessage);
      });
    });

    describe('failed API response', () => {
      beforeEach(() => {
        const limit = 1;
        axiosMock
          .onPut(
            `${updateFreePlanLimitsEndpoint}&${UPDATE_PLAN_LIMIT_PARAM_NAMES.dashboard}=${limit}`,
          )
          .replyOnce(HTTP_STATUS_BAD_REQUEST, {
            message: 'There was a problem processing the request',
          });
        createComponent();
        findDashboardLimitSection().vm.$emit('limit-change', limit);
        return waitForPromises();
      });

      it('passes the error message to the namespace-limits-section', () => {
        expect(findDashboardLimitSection().props()).toMatchObject({
          errorMessage: 'There was a problem processing the request',
        });
      });
    });
  });
});
