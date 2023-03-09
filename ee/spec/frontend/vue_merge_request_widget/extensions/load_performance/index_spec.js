import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import extensionsContainer from '~/vue_merge_request_widget/components/extensions/container';
import { registerExtension } from '~/vue_merge_request_widget/components/extensions';
import loadPerformanceExtension from 'ee/vue_merge_request_widget/extensions/load_performance';
import waitForPromises from 'helpers/wait_for_promises';
import { baseLoadPerformance, headLoadPerformance } from '../../mock_data';

describe('Load performance extension', () => {
  let wrapper;
  let mock;

  const DEFAULT_LOAD_PERFORMANCE = {
    head_path: 'head.json',
    base_path: 'base.json',
  };

  const createComponent = () => {
    wrapper = mount(extensionsContainer, {
      propsData: {
        mr: {
          loadPerformance: {
            ...DEFAULT_LOAD_PERFORMANCE,
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
      mock.onGet(DEFAULT_LOAD_PERFORMANCE.head_path).reply(HTTP_STATUS_OK, headLoadPerformance);
      mock.onGet(DEFAULT_LOAD_PERFORMANCE.base_path).reply(HTTP_STATUS_OK, baseLoadPerformance);

      registerExtension(loadPerformanceExtension);

      await nextTick();

      expect(wrapper.text()).toContain('Load performance test metrics results are being parsed');
    });

    it('should render info about all issues', async () => {
      mock.onGet(DEFAULT_LOAD_PERFORMANCE.head_path).reply(HTTP_STATUS_OK, headLoadPerformance);
      mock.onGet(DEFAULT_LOAD_PERFORMANCE.base_path).reply(HTTP_STATUS_OK, baseLoadPerformance);

      registerExtension(loadPerformanceExtension);

      await waitForPromises();

      expect(wrapper.text()).toContain('Load performance test metrics detected 4 changes');
      expect(wrapper.text()).toContain('1 degraded, 1 same, and 2 improved');
    });

    it('should render info about fixed issues', async () => {
      const head = {
        metrics: {
          checks: {
            fails: 0,
            passes: 100,
            value: 0,
          },
        },
      };
      const base = {
        metrics: {
          checks: {
            fails: 2,
            passes: 55,
            value: 0,
          },
        },
      };

      mock.onGet(DEFAULT_LOAD_PERFORMANCE.head_path).reply(HTTP_STATUS_OK, head);
      mock.onGet(DEFAULT_LOAD_PERFORMANCE.base_path).reply(HTTP_STATUS_OK, base);

      registerExtension(loadPerformanceExtension);

      await waitForPromises();

      expect(wrapper.text()).toContain('Load performance test metrics detected 1 change');
      expect(wrapper.text()).toContain('1 improved');
    });

    it('should render info about added issues', async () => {
      const head = {
        metrics: {
          checks: {
            fails: 1,
            passes: 100,
            value: 0,
          },
        },
      };
      const base = {
        metrics: {
          checks: {
            fails: 0,
            passes: 55,
            value: 0,
          },
        },
      };

      mock.onGet(DEFAULT_LOAD_PERFORMANCE.head_path).reply(HTTP_STATUS_OK, head);
      mock.onGet(DEFAULT_LOAD_PERFORMANCE.base_path).reply(HTTP_STATUS_OK, base);

      registerExtension(loadPerformanceExtension);

      await waitForPromises();
      expect(wrapper.text()).toContain('Load performance test metrics detected 1 change');
      expect(wrapper.text()).toContain('1 degraded');
    });
  });

  describe('expanded data', () => {
    beforeEach(async () => {
      mock.onGet(DEFAULT_LOAD_PERFORMANCE.head_path).reply(HTTP_STATUS_OK, headLoadPerformance);
      mock.onGet(DEFAULT_LOAD_PERFORMANCE.base_path).reply(HTTP_STATUS_OK, baseLoadPerformance);

      registerExtension(loadPerformanceExtension);

      await waitForPromises();

      wrapper
        .find('[data-testid="widget-extension"] [data-testid="toggle-button"]')
        .trigger('click');

      await nextTick();
    });

    it('expanded data list items text', () => {
      const listItems = wrapper.findAll('[data-testid="extension-list-item"]');

      expect(listItems.at(0).text()).toBe('TTFB P90: 100.60 (-3.50) (-3%)');
      expect(listItems.at(1).text()).toBe('RPS: 8.99 (1.20) (+15%)');
      expect(listItems.at(2).text()).toBe('TTFB P95: 125.45 (24.23) (+24%)');
      expect(listItems.at(3).text()).toBe('Checks: 100.00%');
    });
  });
});
