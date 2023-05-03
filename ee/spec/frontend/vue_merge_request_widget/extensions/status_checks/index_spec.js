import * as Sentry from '@sentry/browser';
import { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';

import {
  approvedAndPendingChecks,
  approvedChecks,
  failedChecks,
  pendingAndFailedChecks,
  pendingChecks,
} from 'ee_jest/ci/reports/status_checks_report/mock_data';
import axios from '~/lib/utils/axios_utils';
import extensionsContainer from '~/vue_merge_request_widget/components/extensions/container';
import { registerExtension } from '~/vue_merge_request_widget/components/extensions';
import statusChecksExtension from 'ee/vue_merge_request_widget/extensions/status_checks';
import {
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_NOT_FOUND,
  HTTP_STATUS_OK,
  HTTP_STATUS_UNPROCESSABLE_ENTITY,
} from '~/lib/utils/http_status';
import waitForPromises from 'helpers/wait_for_promises';
import * as StatusCheckRetryApi from 'ee/api/status_check_api';

const resizeWindow = (x) => {
  window.innerWidth = x;
  window.dispatchEvent(new Event('resize'));
};

describe('Status checks extension', () => {
  let wrapper;
  let mock;

  const POLL_INTERVAL_MS = 10000;
  const getChecksEndpoint = 'https://test-get-check';
  const retryCheckEndpoint = 'https://test-retry-check';

  registerExtension(statusChecksExtension);

  const createComponent = (mr) => {
    wrapper = mount(extensionsContainer, {
      propsData: {
        mr: {
          apiStatusChecksPath: getChecksEndpoint,
          apiStatusChecksRetryPath: retryCheckEndpoint,
          canRetryExternalStatusChecks: true,
          ...mr,
        },
      },
    });
  };

  const setupWithResponse = (statusCode, data, mr = {}) => {
    mock.onGet(getChecksEndpoint).reply(statusCode, data, { 'poll-interval': POLL_INTERVAL_MS });

    createComponent(mr);
    jest.advanceTimersByTime(1);

    return waitForPromises();
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.reset();
  });

  describe('summary', () => {
    describe('when loading', () => {
      beforeEach(() => {
        mock.onGet(getChecksEndpoint).reply(() => new Promise());
        createComponent();
      });

      it('should render loading text', async () => {
        jest.advanceTimersByTime(1);
        await nextTick();

        expect(wrapper.text()).toContain('Status checks are being fetched');
      });
    });

    describe('when the fetching fails', () => {
      beforeEach(async () => {
        await setupWithResponse(HTTP_STATUS_NOT_FOUND);
      });

      it('should render the failed text', () => {
        expect(wrapper.text()).toContain('Failed to load status checks');
      });

      it('should render the button to retry fetching all status checks', () => {
        expect(wrapper.text()).toContain('Retry');
      });

      it('should render the button to retry fetching all status checks in mobile viewport', () => {
        resizeWindow(500);
        expect(wrapper.text()).toContain('Retry');
        resizeWindow(1024);
      });
    });

    describe('when the fetching succeeds', () => {
      describe.each`
        state                     | response                    | text
        ${'approved'}             | ${approvedChecks}           | ${'Status checks all passed'}
        ${'pending'}              | ${pendingChecks}            | ${'1 pending'}
        ${'approved and pending'} | ${approvedAndPendingChecks} | ${'1 pending'}
        ${'failed and pending'}   | ${pendingAndFailedChecks}   | ${'1 failed, 1 pending'}
      `('and the status checks are $state', ({ response, text }) => {
        beforeEach(async () => {
          await setupWithResponse(HTTP_STATUS_OK, response);
        });

        it(`renders '${text}' in the report section`, () => {
          expect(wrapper.text()).toContain(text);
        });
      });
    });
  });

  describe('polling', () => {
    it('should not start polling if there are no pending status checks', async () => {
      await setupWithResponse(HTTP_STATUS_OK, approvedChecks);
      jest.advanceTimersByTime(POLL_INTERVAL_MS * 2);
      await waitForPromises();

      expect(mock.history.get.length).toBe(1);
    });

    it('should start polling if there are pending status checks', async () => {
      await setupWithResponse(HTTP_STATUS_OK, pendingChecks);
      jest.advanceTimersByTime(POLL_INTERVAL_MS * 2);
      await waitForPromises();

      expect(mock.history.get.length).toBe(2);
    });

    it('should stop polling once there are no more pending checks', async () => {
      await setupWithResponse(HTTP_STATUS_OK, pendingChecks);
      jest.advanceTimersByTime(POLL_INTERVAL_MS);
      await waitForPromises();

      mock.onGet(getChecksEndpoint).reply(HTTP_STATUS_OK, approvedChecks);
      jest.advanceTimersByTime(POLL_INTERVAL_MS * 2);
      await waitForPromises();

      expect(mock.history.get.length).toBe(3);
    });
  });

  describe('expanded data', () => {
    beforeEach(async () => {
      await setupWithResponse(HTTP_STATUS_OK, [
        ...approvedAndPendingChecks,
        {
          id: 4,
          name: '<a class="test" data-test">Foo',
          external_url: 'http://foo',
          status: 'passed',
        },
      ]);

      wrapper
        .find('[data-testid="widget-extension"] [data-testid="toggle-button"]')
        .trigger('click');
    });

    it('shows the expanded list of text items', () => {
      const listItems = wrapper.findAll('[data-testid="extension-list-item"]');

      expect(listItems).toHaveLength(3);
      expect(listItems.at(0).text()).toMatchInterpolatedText('Foo: http://foo Status Check ID: 1');
      expect(listItems.at(1).text()).toMatchInterpolatedText(
        '<a class="test" data-test">Foo: http://foo Status Check ID: 4',
      );
      expect(listItems.at(2).text()).toMatchInterpolatedText(
        'Foo Bar: http://foobar Status Check ID: 2',
      );
    });
  });

  describe('when unable to retry failed checks', () => {
    beforeEach(async () => {
      await setupWithResponse(HTTP_STATUS_OK, failedChecks, {
        canRetryExternalStatusChecks: false,
      });
      wrapper
        .find('[data-testid="widget-extension"] [data-testid="toggle-button"]')
        .trigger('click');
    });

    it('should not show a retry button', () => {
      const listItem = wrapper.findAll('[data-testid="extension-list-item"]').at(0);
      const actionButton = listItem.find('[data-testid="extension-actions-button"]');

      expect(actionButton.exists()).toBe(false);
    });
  });

  describe('when retrying failed checks', () => {
    describe.each`
      state         | response
      ${'approved'} | ${approvedChecks}
      ${'pending'}  | ${pendingChecks}
    `('and the status checks are $state', ({ response }) => {
      beforeEach(async () => {
        await setupWithResponse(HTTP_STATUS_OK, response);
        wrapper
          .find('[data-testid="widget-extension"] [data-testid="toggle-button"]')
          .trigger('click');
      });

      it(`should not show a retry button`, () => {
        const listItem = wrapper.findAll('[data-testid="extension-list-item"]').at(0);
        const actionButton = listItem.find('[data-testid="extension-actions-button"]');

        expect(actionButton.exists()).toBe(false);
      });
    });

    describe('and the status checks are failed', () => {
      function getAndClickRetryActionButton() {
        const listItem = wrapper.findAll('[data-testid="extension-list-item"]').at(0);
        const actionButton = listItem.find('[data-testid="extension-actions-button"]');
        actionButton.trigger('click');

        return actionButton;
      }

      beforeEach(async () => {
        await setupWithResponse(HTTP_STATUS_OK, failedChecks);
        wrapper
          .find('[data-testid="widget-extension"] [data-testid="toggle-button"]')
          .trigger('click');
      });

      it(`should show a retry button`, () => {
        const listItem = wrapper.findAll('[data-testid="extension-list-item"]').at(0);
        const actionButton = listItem.find('[data-testid="extension-actions-button"]');

        expect(actionButton.exists()).toBe(true);
        expect(actionButton.text()).toBe('Retry');
      });

      it(`should show a retry button at mobile viewport`, () => {
        resizeWindow(500);

        const listItem = wrapper.findAll('[data-testid="extension-list-item"]').at(0);
        const actionButton = listItem.find('[data-testid="extension-actions-button"]');

        expect(actionButton.exists()).toBe(true);
        expect(actionButton.text()).toBe('Retry');

        resizeWindow(1024);
      });

      it('should show a loading state when clicked', async () => {
        jest
          .spyOn(StatusCheckRetryApi, 'mrStatusCheckRetry')
          .mockResolvedValue({ response: { status: HTTP_STATUS_OK, data: {} } });

        const actionButton = getAndClickRetryActionButton();
        await nextTick();

        expect(actionButton.attributes('disabled')).toBeDefined();
        expect(actionButton.find('[aria-label="Loading"]').exists()).toBe(true);
      });

      it('should refetch the status checks when retry was successful', async () => {
        jest
          .spyOn(StatusCheckRetryApi, 'mrStatusCheckRetry')
          .mockResolvedValue({ response: { status: HTTP_STATUS_OK, data: {} } });
        mock.onGet(getChecksEndpoint).reply(HTTP_STATUS_OK, pendingChecks);

        getAndClickRetryActionButton();
        await waitForPromises();

        expect(mock.history.get.length).toBe(1);
        expect(mock.history.get[0].url).toBe(getChecksEndpoint);
      });

      it('should refetch the status checks when retried status check is already approved', async () => {
        jest
          .spyOn(StatusCheckRetryApi, 'mrStatusCheckRetry')
          .mockRejectedValue({ response: { status: HTTP_STATUS_UNPROCESSABLE_ENTITY, data: {} } });
        mock.onGet(getChecksEndpoint).reply(HTTP_STATUS_OK, approvedChecks);

        getAndClickRetryActionButton();
        await waitForPromises();

        expect(mock.history.get.length).toBe(1);
        expect(mock.history.get[0].url).toBe(getChecksEndpoint);
      });

      it('should log to Sentry when the server errors', async () => {
        const sentrySpy = jest.spyOn(Sentry, 'captureException');
        jest
          .spyOn(StatusCheckRetryApi, 'mrStatusCheckRetry')
          .mockRejectedValue({ status: HTTP_STATUS_INTERNAL_SERVER_ERROR, data: {} });

        getAndClickRetryActionButton();
        await waitForPromises();

        expect(sentrySpy).toHaveBeenCalledTimes(1);
        sentrySpy.mockRestore();
      });
    });
  });
});
