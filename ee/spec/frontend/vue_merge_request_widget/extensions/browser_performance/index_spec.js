import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import extensionsContainer from '~/vue_merge_request_widget/components/extensions/container';
import { registerExtension } from '~/vue_merge_request_widget/components/extensions';
import browserPerformanceExtension from 'ee/vue_merge_request_widget/extensions/browser_performance';
import waitForPromises from 'helpers/wait_for_promises';
import { baseBrowserPerformance, headBrowserPerformance } from '../../mock_data';

describe('Browser performance extension', () => {
  let wrapper;
  let mock;

  const DEFAULT_BROWSER_PERFORMANCE = {
    head_path: 'head.json',
    base_path: 'base.json',
  };

  const createComponent = () => {
    wrapper = mount(extensionsContainer, {
      propsData: {
        mr: {
          browserPerformance: {
            ...DEFAULT_BROWSER_PERFORMANCE,
          },
        },
      },
    });
  };

  beforeEach(() => {
    createComponent();

    mock = new MockAdapter(axios);
  });

  describe('summary', () => {
    it('should render loading text', async () => {
      mock
        .onGet(DEFAULT_BROWSER_PERFORMANCE.head_path)
        .reply(HTTP_STATUS_OK, headBrowserPerformance);
      mock
        .onGet(DEFAULT_BROWSER_PERFORMANCE.base_path)
        .reply(HTTP_STATUS_OK, baseBrowserPerformance);

      registerExtension(browserPerformanceExtension);

      await nextTick();

      expect(wrapper.text()).toContain('Browser performance test metrics results are being parsed');
    });

    it('should render info', async () => {
      mock
        .onGet(DEFAULT_BROWSER_PERFORMANCE.head_path)
        .reply(HTTP_STATUS_OK, headBrowserPerformance);
      mock
        .onGet(DEFAULT_BROWSER_PERFORMANCE.base_path)
        .reply(HTTP_STATUS_OK, baseBrowserPerformance);

      registerExtension(browserPerformanceExtension);

      await waitForPromises();

      expect(wrapper.text()).toContain('Browser performance test metrics');
      expect(wrapper.text()).toContain('2 degraded, 1 same, and 1 improved');
    });

    it('should render info about fixed issues', async () => {
      const head = [
        {
          metrics: [
            {
              name: 'Total Score',
              value: 90,
              desiredSize: 'larger',
            },
          ],
        },
      ];

      const base = [
        {
          metrics: [
            {
              name: 'Total Score',
              value: 80,
              desiredSize: 'larger',
            },
          ],
        },
      ];

      mock.onGet(DEFAULT_BROWSER_PERFORMANCE.head_path).reply(HTTP_STATUS_OK, head);
      mock.onGet(DEFAULT_BROWSER_PERFORMANCE.base_path).reply(HTTP_STATUS_OK, base);

      registerExtension(browserPerformanceExtension);

      await waitForPromises();

      expect(wrapper.text()).toContain('Browser performance test metrics: 1 change');
      expect(wrapper.text()).toContain('1 improved');
    });

    it('should render info about added issues', async () => {
      const head = [
        {
          metrics: [
            {
              name: 'Total Score',
              value: 80,
              desiredSize: 'larger',
            },
          ],
        },
      ];

      const base = [
        {
          metrics: [
            {
              name: 'Total Score',
              value: 90,
              desiredSize: 'larger',
            },
          ],
        },
      ];

      mock.onGet(DEFAULT_BROWSER_PERFORMANCE.head_path).reply(HTTP_STATUS_OK, head);
      mock.onGet(DEFAULT_BROWSER_PERFORMANCE.base_path).reply(HTTP_STATUS_OK, base);

      registerExtension(browserPerformanceExtension);

      await waitForPromises();

      expect(wrapper.text()).toContain('Browser performance test metrics: 1 change');
      expect(wrapper.text()).toContain('1 degraded');
    });
  });

  describe('expanded data', () => {
    beforeEach(async () => {
      mock
        .onGet(DEFAULT_BROWSER_PERFORMANCE.head_path)
        .reply(HTTP_STATUS_OK, headBrowserPerformance);
      mock
        .onGet(DEFAULT_BROWSER_PERFORMANCE.base_path)
        .reply(HTTP_STATUS_OK, baseBrowserPerformance);

      registerExtension(browserPerformanceExtension);

      await waitForPromises();

      wrapper
        .find('[data-testid="widget-extension"] [data-testid="toggle-button"]')
        .trigger('click');

      await nextTick();
    });

    it('shows the expanded list of text items', () => {
      const listItems = wrapper.findAll('[data-testid="extension-list-item"]');

      expect(listItems.at(0).text()).toBe('Speed Index: 1155 (-10) (-1%) in /some/path');
      expect(listItems.at(1).text()).toBe('Total Score: 80 (-2) (-2%) in /some/path');
      expect(listItems.at(2).text()).toBe('Transfer Size (KB): 1070.09 (5) (+0%) in /some/path');
    });
  });
});
