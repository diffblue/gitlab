import { GlSkeletonLoader } from '@gitlab/ui';
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import UsageByMonth from 'ee/usage_quotas/transfer/components/usage_by_month.vue';
import { USAGE_BY_MONTH_HEADER } from 'ee/usage_quotas/constants';

jest.mock('~/lib/utils/icon_utils', () => ({
  getSvgIconPathContent: jest
    .fn()
    .mockImplementation((name) => Promise.resolve(`${name}-svg-path-mock`)),
}));

describe('UsageByMonth', () => {
  let wrapper;

  const defaultPropsData = {
    chartData: [
      ['Jan 2023', '5000861558'],
      ['Feb 2023', '6651307793'],
      ['Mar 2023', '5368547376'],
      ['Apr 2023', '4055795925'],
    ],
    loading: false,
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(UsageByMonth, {
      propsData: { ...defaultPropsData, ...propsData },
    });
  };

  const findGlAreaChart = () => wrapper.findComponent(GlAreaChart);

  it('renders `Usage by month` heading', () => {
    createComponent();

    expect(wrapper.findByRole('heading', { name: USAGE_BY_MONTH_HEADER }).exists()).toBe(true);
  });

  describe('when `loading` prop is `true`', () => {
    beforeEach(async () => {
      createComponent({
        propsData: {
          loading: true,
        },
      });

      await waitForPromises();
    });

    it('renders `GlSkeletonLoader` component', () => {
      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
    });
  });

  describe('when `loading` prop is `false`', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('renders `GlAreaChart` component and correctly passes props', () => {
      expect(findGlAreaChart().props()).toMatchObject({
        data: [{ name: UsageByMonth.i18n.DATA_NAME, data: defaultPropsData.chartData }],
        option: {
          grid: { left: 80 },
          xAxis: { name: UsageByMonth.i18n.MONTH, type: 'category' },
          yAxis: {
            name: UsageByMonth.i18n.USAGE,
            nameGap: 65,
            axisLabel: { formatter: expect.any(Function) },
          },
          toolbox: {
            feature: {
              dataZoom: {
                icon: {
                  zoom: 'path://marquee-selection-svg-path-mock',
                  back: 'path://redo-svg-path-mock',
                },
              },
              restore: {
                icon: 'path://repeat-svg-path-mock',
              },
              saveAsImage: {
                icon: 'path://download-svg-path-mock',
              },
            },
          },
        },
      });
    });

    describe('when tooltip is shown', () => {
      beforeEach(() => {
        findGlAreaChart().vm.formatTooltipText({
          seriesData: [
            {
              value: ['Feb 2023', '6651307793'],
            },
          ],
        });
      });

      it('displays title', () => {
        expect(
          findGlAreaChart().vm.$scopedSlots['tooltip-title']()[0].text,
        ).toMatchInterpolatedText('Feb 2023 (Month)');
      });

      it('displays value as human size', () => {
        expect(
          findGlAreaChart().vm.$scopedSlots['tooltip-content']()[0].text,
        ).toMatchInterpolatedText('6.2 GiB');
      });
    });
  });
});
