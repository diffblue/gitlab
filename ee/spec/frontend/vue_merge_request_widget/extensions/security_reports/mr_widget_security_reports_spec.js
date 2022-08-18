import { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import MRSecurityWidget from 'ee/vue_merge_request_widget/extensions/security_reports/mr_widget_security_reports.vue';
import SummaryText from 'ee/vue_merge_request_widget/extensions/security_reports/summary_text.vue';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import Widget from '~/vue_merge_request_widget/components/widget/widget.vue';
import axios from '~/lib/utils/axios_utils';

describe('MR Widget Security Reports', () => {
  let wrapper;
  let mockAxios;

  const createComponent = ({ propsData, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(MRSecurityWidget, {
      propsData: {
        mr: {},
        ...propsData,
      },
    });
  };

  const findWidget = () => wrapper.findComponent(Widget);
  const findSummaryText = () => wrapper.findComponent(SummaryText);

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

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

    it('should not be collapsible', () => {
      expect(findWidget().props('isCollapsible')).toBe(false);
    });
  });

  describe('with MR data', () => {
    const reportEndpoints = {
      sastComparisonPath: '/my/sast/endpoint',
      dastComparisonPath: '/my/dast/endpoint',
    };

    const mockWithData = () => {
      mockAxios
        .onGet(reportEndpoints.sastComparisonPath)
        .replyOnce(200, { added: [{ id: 1 }, { id: 2 }] });

      mockAxios
        .onGet(reportEndpoints.dastComparisonPath)
        .replyOnce(200, { added: [{ id: 5 }, { id: 3 }] });
    };

    it('computes the total number of new potential vulnerabilities correctly', async () => {
      mockWithData();

      createComponent({
        propsData: { mr: { ...reportEndpoints } },
        mountFn: mountExtended,
      });

      await waitForPromises();
      expect(findSummaryText().props()).toMatchObject({ totalNewVulnerabilities: 4 });
    });

    it('tells the widget to be collapsible only if there is data', async () => {
      mockWithData();

      createComponent({
        propsData: { mr: { ...reportEndpoints } },
        mountFn: mountExtended,
      });

      expect(findWidget().props('isCollapsible')).toBe(false);
      await waitForPromises();
      expect(findWidget().props('isCollapsible')).toBe(true);
    });
  });
});
