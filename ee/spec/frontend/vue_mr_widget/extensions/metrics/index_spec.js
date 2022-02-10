import MockAdapter from 'axios-mock-adapter';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { trimText } from 'helpers/text_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import extensionsContainer from '~/vue_merge_request_widget/components/extensions/container';
import { registerExtension } from '~/vue_merge_request_widget/components/extensions';
import metricsExtension from 'ee/vue_merge_request_widget/extensions/metrics';
import httpStatusCodes from '~/lib/utils/http_status';

const changedMetric = {
  name: 'name',
  value: 'value',
  previous_value: 'prev',
};
const unchangedMetric = {
  name: 'name',
  value: 'value',
};

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

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  describe('summary', () => {
    it('displays loading text', () => {
      mockApi(httpStatusCodes.OK);

      createComponent();

      expect(wrapper.text()).toBe('Metrics reports are loading');
    });

    it('displays failed loading text', async () => {
      mockApi(httpStatusCodes.INTERNAL_SERVER_ERROR);

      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toBe('Metrics reports failed loading results');
    });

    it('displays detected changes', async () => {
      mockApi(httpStatusCodes.OK, { existing_metrics: [changedMetric, changedMetric] });

      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toBe('Metrics report scanning detected 2 changes');
    });

    it('displays no detected changes', async () => {
      mockApi(httpStatusCodes.OK, { existing_metrics: [unchangedMetric] });

      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toBe('Metrics report scanning did not detect any changes');
    });
  });
  describe('expanded data', () => {
    beforeEach(async () => {
      mockApi(httpStatusCodes.OK, {
        new_metrics: [unchangedMetric, unchangedMetric],
        existing_metrics: [changedMetric, changedMetric, unchangedMetric, unchangedMetric],
        removed_metrics: [unchangedMetric, unchangedMetric],
      });
      createComponent();

      await waitForPromises();

      findToggleCollapsedButton().trigger('click');

      await waitForPromises();
    });

    it('displays all metrics', async () => {
      expect(findAllExtensionListItems()).toHaveLength(8);
    });

    it.each`
      index | ordinal     | type           | expectedText
      ${0}  | ${'first'}  | ${'changed'}   | ${'Changed name: value (prev)'}
      ${1}  | ${'second'} | ${'changed'}   | ${'name: value (prev)'}
      ${2}  | ${'first'}  | ${'new'}       | ${'New name: value'}
      ${3}  | ${'second'} | ${'new'}       | ${'name: value'}
      ${4}  | ${'first'}  | ${'removed'}   | ${'Removed name: value'}
      ${5}  | ${'second'} | ${'removed'}   | ${'name: value'}
      ${6}  | ${'first'}  | ${'unchanged'} | ${'Unchanged name: value (No changes)'}
      ${7}  | ${'second'} | ${'unchanged'} | ${'name: value (No changes)'}
    `('formats $ordinal $type metric correctly', ({ index, expectedText }) => {
      expect(trimText(findAllExtensionListItems().at(index).text())).toBe(expectedText);
    });
  });
});
