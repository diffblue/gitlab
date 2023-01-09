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
import httpStatus from '~/lib/utils/http_status';
import waitForPromises from 'helpers/wait_for_promises';
import * as StatusCheckRetryApi from 'ee/api/status_check_api';

describe('Status checks extension', () => {
  let wrapper;
  let mock;

  const getChecksEndpoint = 'https://test-get-check';
  const retryCheckEndpoint = 'https://test-retry-check';

  registerExtension(statusChecksExtension);

  const createComponent = () => {
    wrapper = mount(extensionsContainer, {
      propsData: {
        mr: {
          apiStatusChecksPath: getChecksEndpoint,
          apiStatusChecksRetryPath: retryCheckEndpoint,
        },
      },
    });
  };

  const setupWithResponse = (statusCode, data) => {
    mock.onGet(getChecksEndpoint).reply(statusCode, data);

    createComponent();

    return waitForPromises();
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('summary', () => {
    describe('when loading', () => {
      beforeEach(async () => {
        await setupWithResponse(httpStatus.OK, new Promise(() => {}));
      });

      it('should render loading text', () => {
        expect(wrapper.text()).toContain('Status checks are being fetched');
      });
    });

    describe('when the fetching fails', () => {
      beforeEach(async () => {
        await setupWithResponse(httpStatus.NOT_FOUND);
      });

      it('should render the failed text', () => {
        expect(wrapper.text()).toContain('Failed to load status checks');
      });

      it('should render the button to retry fetching all status checks', () => {
        expect(wrapper.text()).toContain('Retry');
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
          await setupWithResponse(httpStatus.OK, response);
        });

        it(`renders '${text}' in the report section`, () => {
          expect(wrapper.text()).toContain(text);
        });
      });
    });
  });

  describe('expanded data', () => {
    beforeEach(async () => {
      await setupWithResponse(httpStatus.OK, [
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
      expect(listItems.at(0).text()).toBe('Foo: http://foo');
      expect(listItems.at(1).text()).toBe('<a class="test" data-test">Foo: http://foo');
      expect(listItems.at(2).text()).toBe('Foo Bar: http://foobar');
    });
  });

  describe('when retrying failed checks', () => {
    describe.each`
      state         | response
      ${'approved'} | ${approvedChecks}
      ${'pending'}  | ${pendingChecks}
    `('and the status checks are $state', ({ response }) => {
      beforeEach(async () => {
        await setupWithResponse(httpStatus.OK, response);
        wrapper
          .find('[data-testid="widget-extension"] [data-testid="toggle-button"]')
          .trigger('click');
      });

      it(`should not show a retry button`, async () => {
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
        await setupWithResponse(httpStatus.OK, failedChecks);
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

      it('should show a loading state when clicked', async () => {
        jest
          .spyOn(StatusCheckRetryApi, 'mrStatusCheckRetry')
          .mockResolvedValue({ response: { status: 200, data: {} } });

        const actionButton = getAndClickRetryActionButton();
        await nextTick();

        expect(actionButton.attributes('disabled')).toBe('disabled');
        expect(actionButton.find('[aria-label="Loading"]').exists()).toBe(true);
      });

      it('should refetch the status checks when retry was successful', async () => {
        jest
          .spyOn(StatusCheckRetryApi, 'mrStatusCheckRetry')
          .mockResolvedValue({ response: { status: 200, data: {} } });
        mock.onGet(getChecksEndpoint).reply(200, pendingChecks);
        const getSpy = jest.spyOn(axios, 'get');

        getAndClickRetryActionButton();
        await waitForPromises();

        expect(getSpy).toHaveBeenCalledTimes(1);
        expect(getSpy).toHaveBeenCalledWith(getChecksEndpoint);
      });

      it('should refetch the status checks when retried status check is already approved', async () => {
        const alreadyApprovedStatusCode = 422;
        jest
          .spyOn(StatusCheckRetryApi, 'mrStatusCheckRetry')
          .mockRejectedValue({ response: { status: alreadyApprovedStatusCode, data: {} } });
        mock.onGet(getChecksEndpoint).reply(200, approvedChecks);
        const getSpy = jest.spyOn(axios, 'get');

        getAndClickRetryActionButton();
        await waitForPromises();

        expect(getSpy).toHaveBeenCalledTimes(1);
        expect(getSpy).toHaveBeenCalledWith(getChecksEndpoint);
      });

      it('should log to Sentry when the server errors', async () => {
        const sentrySpy = jest.spyOn(Sentry, 'captureException');
        jest
          .spyOn(StatusCheckRetryApi, 'mrStatusCheckRetry')
          .mockRejectedValue({ status: 500, data: {} });

        getAndClickRetryActionButton();
        await waitForPromises();

        expect(sentrySpy).toHaveBeenCalledTimes(1);
        sentrySpy.mockRestore();
      });
    });
  });
});
