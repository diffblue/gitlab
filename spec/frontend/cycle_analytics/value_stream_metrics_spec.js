import { GlDeprecatedSkeletonLoading as GlSkeletonLoading } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import ValueStreamMetrics from '~/cycle_analytics/components/value_stream_metrics.vue';
import createFlash from '~/flash';
import { group, metricsData } from './mock_data';

jest.mock('~/flash');

describe('ValueStreamMetrics', () => {
  let wrapper;
  let mockGetValueStreamSummaryMetrics;

  const { full_path: requestPath } = group;
  const fakeReqName = 'Mock metrics';

  const createComponent = ({ requestParams = {} } = {}) => {
    return shallowMount(ValueStreamMetrics, {
      propsData: {
        requestPath,
        requestParams,
        requests: [{ request: mockGetValueStreamSummaryMetrics, name: fakeReqName }],
      },
    });
  };

  const findMetrics = () => wrapper.findAllComponents(GlSingleStat);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('will display a loading icon if `true`', async () => {
    mockGetValueStreamSummaryMetrics = jest.fn().mockResolvedValue({ data: metricsData });
    wrapper = createComponent();
    await wrapper.vm.$nextTick();

    expect(wrapper.find(GlSkeletonLoading).exists()).toBe(true);
  });

  describe('with successful requests', () => {
    beforeEach(async () => {
      mockGetValueStreamSummaryMetrics = jest.fn().mockResolvedValue({ data: metricsData });
      wrapper = createComponent();

      await waitForPromises();
    });

    it('fetches data for the `getValueStreamSummaryMetrics` request', () => {
      expect(mockGetValueStreamSummaryMetrics).toHaveBeenCalledWith(requestPath, {});
    });

    it.each`
      index | value                   | title                   | unit
      ${0}  | ${metricsData[0].value} | ${metricsData[0].title} | ${metricsData[0].unit}
      ${1}  | ${metricsData[1].value} | ${metricsData[1].title} | ${metricsData[1].unit}
      ${2}  | ${metricsData[2].value} | ${metricsData[2].title} | ${metricsData[2].unit}
      ${3}  | ${metricsData[3].value} | ${metricsData[3].title} | ${metricsData[3].unit}
    `(
      'renders a single stat component for the $title with value and unit',
      ({ index, value, title, unit }) => {
        const metric = findMetrics().at(index);
        const expectedUnit = unit ?? '';

        expect(metric.props('value')).toBe(value);
        expect(metric.props('title')).toBe(title);
        expect(metric.props('unit')).toBe(expectedUnit);
      },
    );

    it('will not display a loading icon', () => {
      expect(wrapper.find(GlSkeletonLoading).exists()).toBe(false);
    });

    describe('with additional params', () => {
      beforeEach(async () => {
        wrapper = createComponent({
          requestParams: {
            'project_ids[]': [1],
            created_after: '2020-01-01',
            created_before: '2020-02-01',
          },
        });

        await waitForPromises();
      });

      it('fetches data for the `getValueStreamSummaryMetrics` request', () => {
        expect(mockGetValueStreamSummaryMetrics).toHaveBeenCalledWith(requestPath, {
          'project_ids[]': [1],
          created_after: '2020-01-01',
          created_before: '2020-02-01',
        });
      });
    });
  });

  describe('with a request failing', () => {
    beforeEach(async () => {
      mockGetValueStreamSummaryMetrics = jest.fn().mockRejectedValue();
      wrapper = createComponent();

      await waitForPromises();
    });

    it('it should render a error message', () => {
      expect(createFlash).toHaveBeenCalledWith({
        message: `There was an error while fetching value stream analytics ${fakeReqName} data.`,
      });
    });
  });
});
