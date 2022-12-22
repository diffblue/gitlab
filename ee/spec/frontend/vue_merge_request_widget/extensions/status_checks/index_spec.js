import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import {
  approvedChecks,
  pendingChecks,
  approvedAndPendingChecks,
  pendingAndFailedChecks,
} from 'ee_jest/ci/reports/status_checks_report/mock_data';
import axios from '~/lib/utils/axios_utils';
import extensionsContainer from '~/vue_merge_request_widget/components/extensions/container';
import { registerExtension } from '~/vue_merge_request_widget/components/extensions';
import statusChecksExtension from 'ee/vue_merge_request_widget/extensions/status_checks';
import httpStatus, { HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';
import waitForPromises from 'helpers/wait_for_promises';

describe('Status checks extension', () => {
  let wrapper;
  let mock;

  const endpoint = 'https://test';

  registerExtension(statusChecksExtension);

  const createComponent = () => {
    wrapper = mount(extensionsContainer, {
      propsData: {
        mr: {
          apiStatusChecksPath: endpoint,
        },
      },
    });
  };

  const setupWithResponse = (statusCode, data) => {
    mock.onGet(endpoint).reply(statusCode, data);

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
        await setupWithResponse(HTTP_STATUS_NOT_FOUND);
      });

      it('should render the failed text', () => {
        expect(wrapper.text()).toContain('Failed to load status checks');
      });

      it('should render the retry button', () => {
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
});
