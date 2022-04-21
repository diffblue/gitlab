import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import extensionsContainer from '~/vue_merge_request_widget/components/extensions/container';
import { registerExtension } from '~/vue_merge_request_widget/components/extensions';
import statusChecksExtension from 'ee/vue_merge_request_widget/extensions/status_checks';
import httpStatus from '~/lib/utils/http_status';
import waitForPromises from 'helpers/wait_for_promises';
import {
  approvedChecks,
  pendingChecks,
  approvedAndPendingChecks,
  pendingAndFailedChecks,
} from 'ee_jest/reports/status_checks_report/mock_data';

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
        await setupWithResponse(httpStatus.NOT_FOUND);
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
      await setupWithResponse(httpStatus.OK, approvedAndPendingChecks);

      wrapper
        .find('[data-testid="widget-extension"] [data-testid="toggle-button"]')
        .trigger('click');
    });

    it('shows the expanded list of text items', () => {
      const listItems = wrapper.findAll('[data-testid="extension-list-item"]');

      expect(listItems).toHaveLength(2);
      expect(listItems.at(0).text()).toBe('Foo: http://foo');
      expect(listItems.at(1).text()).toBe('Foo Bar: http://foobar');
    });
  });
});
