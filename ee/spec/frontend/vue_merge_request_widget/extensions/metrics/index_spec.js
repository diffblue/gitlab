import MockAdapter from 'axios-mock-adapter';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { trimText } from 'helpers/text_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import extensionsContainer from '~/vue_merge_request_widget/components/extensions/container';
import { registerExtension } from '~/vue_merge_request_widget/components/extensions';
import metricsExtension from 'ee/vue_merge_request_widget/extensions/metrics';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { metricsResponse, changedMetric, unchangedMetric } from './mock_data';

describe('Metrics extension', () => {
  let wrapper;
  let mock;

  registerExtension(metricsExtension);

  const endpoint = '/root/repo/-/merge_requests/4/metrics_reports.json';

  const mockApi = (statusCode, data) => {
    mock.onGet(endpoint).reply(statusCode, data);
  };

  const findToggleCollapsedButton = () => wrapper.findByTestId('toggle-button');
  const findAllExtensionListItems = () => wrapper.findAllByTestId('extension-list-item');

  const createComponent = () => {
    wrapper = mountExtended(extensionsContainer, {
      propsData: {
        mr: {
          metricsReportsPath: endpoint,
        },
      },
    });
  };

  const createExpandedWidgetWithData = async (data = metricsResponse) => {
    mockApi(HTTP_STATUS_OK, data);
    createComponent();

    await waitForPromises();

    findToggleCollapsedButton().trigger('click');

    await waitForPromises();
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('summary', () => {
    it('displays loading text', () => {
      mockApi(HTTP_STATUS_OK);

      createComponent();

      expect(wrapper.text()).toBe('Metrics reports are loading');
    });

    it('displays failed loading text', async () => {
      mockApi(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toBe('Metrics reports failed to load results');
    });

    it('displays detected changes and is expandable', async () => {
      mockApi(HTTP_STATUS_OK, { existing_metrics: [changedMetric, changedMetric] });

      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toBe('Metrics reports: 2 changes');
      expect(findToggleCollapsedButton().exists()).toBe(true);
    });

    it('displays no detected changes and is not expandable', async () => {
      mockApi(HTTP_STATUS_OK, { existing_metrics: [unchangedMetric] });

      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toBe('Metrics report scanning detected no new changes');
      expect(findToggleCollapsedButton().exists()).toBe(false);
    });
  });

  describe('expanded data', () => {
    describe('new and removed metrics', () => {
      beforeEach(async () => {
        await createExpandedWidgetWithData();
      });

      it.each`
        index | ordinal     | type         | expectedText
        ${0}  | ${'first'}  | ${'new'}     | ${'New gem_size_mb{name=pg}: 3.0'}
        ${1}  | ${'second'} | ${'new'}     | ${'memory_static_objects_retained_items: 258835'}
        ${2}  | ${'first'}  | ${'removed'} | ${'Removed gem_size_mb{name=charlock_holmes}: 2.7'}
        ${3}  | ${'second'} | ${'removed'} | ${'gem_size_mb{name=omniauth-auth0}: 0.5'}
      `('formats $ordinal $type metric correctly', ({ index, expectedText }) => {
        expect(trimText(findAllExtensionListItems().at(index).text())).toBe(expectedText);
      });
    });

    describe('changed and unchanged metrics', () => {
      beforeEach(async () => {
        await createExpandedWidgetWithData({
          existing_metrics: metricsResponse.existing_metrics,
        });
      });

      it.each`
        index | ordinal     | type           | expectedText
        ${0}  | ${'first'}  | ${'changed'}   | ${'Changed memory_static_objects_allocated_items: 1 (1552382)'}
        ${1}  | ${'second'} | ${'changed'}   | ${'memory_static_objects_retained_mb: 30.6 (30.5)'}
        ${2}  | ${'first'}  | ${'unchanged'} | ${'No changes gem_total_size_mb: 194.8'}
        ${3}  | ${'second'} | ${'unchanged'} | ${'memory_static_objects_allocated_mb: 163.7'}
      `('formats $ordinal $type metric correctly', ({ index, expectedText }) => {
        expect(trimText(findAllExtensionListItems().at(index).text())).toBe(expectedText);
      });
    });
  });

  describe('changed metrics sorting', () => {
    it('sorts changed metrics by delta', async () => {
      await createExpandedWidgetWithData({
        existing_metrics: [
          { name: 'small_change', value: '1', previous_value: '0' },
          { name: 'medium_change', value: '-10', previous_value: '0' },
          { name: 'large_change', value: '100.1', previous_value: '0' },
        ],
      });

      expect(findAllExtensionListItems().at(0).text()).toContain('large_change');
      expect(findAllExtensionListItems().at(1).text()).toContain('medium_change');
      expect(findAllExtensionListItems().at(2).text()).toContain('small_change');
    });

    it('sorts non-numeric metrics before numeric metrics', async () => {
      await createExpandedWidgetWithData({
        existing_metrics: [
          { name: 'medium_change', value: '-10', previous_value: '0' },
          { name: 'large_change', value: '100.1', previous_value: '0' },
          {
            name: 'non-numeric_change',
            value: 'group::pipeline security',
            previous_value: 'group::testing',
          },
        ],
      });

      expect(findAllExtensionListItems().at(0).text()).toContain('non-numeric_change');
      expect(findAllExtensionListItems().at(1).text()).toContain('large_change');
      expect(findAllExtensionListItems().at(2).text()).toContain('medium_change');
    });
  });
});
