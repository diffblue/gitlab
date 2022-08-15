import { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import MRSecurityWidget from 'ee/vue_merge_request_widget/extensions/security_reports/mr_widget_security_reports.vue';
import SummaryText from 'ee/vue_merge_request_widget/extensions/security_reports/summary_text.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Widget from '~/vue_merge_request_widget/components/widget/widget.vue';
import axios from '~/lib/utils/axios_utils';

describe('MR Widget Security Reports', () => {
  let wrapper;
  let mockAxios;

  const createComponent = ({ propsData } = {}) => {
    mockAxios = new MockAdapter(axios);
    wrapper = shallowMountExtended(MRSecurityWidget, {
      propsData: {
        mr: {},
        ...propsData,
      },
    });
  };

  const findWidget = () => wrapper.findComponent(Widget);
  const findSummaryText = () => wrapper.findComponent(SummaryText);

  afterEach(() => {
    wrapper.destroy();
    mockAxios.restore();
  });

  describe('with empty MR data', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should mount the widget component', () => {
      expect(findWidget().props()).toMatchObject({
        statusIconName: 'success',
        widgetName: 'MRSecurityWidget',
        errorText: 'Security reports failed loading results',
        loadingText: 'Loading',
        fetchCollapsedData: wrapper.vm.fetchCollapsedData,
        multiPolling: true,
      });
    });

    it('fetchCollapsedData - returns an empty list of endpoints when the paths are missing from the MR data', () => {
      expect(wrapper.vm.fetchCollapsedData().length).toBe(0);
    });

    it('handles loading state', async () => {
      expect(findSummaryText().props()).toMatchObject({ isLoading: false });
      findWidget().vm.$emit('is-loading', true);
      await nextTick();
      expect(findSummaryText().props()).toMatchObject({ isLoading: true });
    });
  });

  describe('with MR data', () => {
    const reportEndpoints = {
      sastComparisonPath: '/my/sast/endpoint',
      dastComparisonPath: '/my/dast/endpoint',
    };

    beforeEach(() => {
      createComponent({
        propsData: {
          mr: {
            ...reportEndpoints,
          },
        },
      });
    });

    it('fetchCollapsedData - returns a list of endpoints', async () => {
      mockAxios.onGet(reportEndpoints.sastComparisonPath).replyOnce(200);
      mockAxios.onGet(reportEndpoints.dastComparisonPath).replyOnce(200);

      const endpoints = wrapper.vm.fetchCollapsedData();
      expect(endpoints.length).toBe(2);

      await Promise.all(endpoints.map((ep) => ep()));

      expect(mockAxios.history.get).toHaveLength(2);
    });
  });
});
