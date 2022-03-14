import { shallowMount } from '@vue/test-utils';
import { GlBadge, GlPopover } from '@gitlab/ui';
import ValueStreamAggregationStatus, {
  LAST_UPDATED_TEXT,
  NEXT_UPDATE_TEXT,
  POPOVER_TITLE,
  toYmdhs,
} from 'ee/analytics/cycle_analytics/components/value_stream_aggregation_status.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { aggregationData } from '../mock_data';

const createComponent = (props = {}) =>
  extendedWrapper(
    shallowMount(ValueStreamAggregationStatus, {
      propsData: {
        data: aggregationData,
        ...props,
      },
    }),
  );

describe('ValueStreamAggregationStatus', () => {
  let wrapper = null;

  const findBadge = () => wrapper.findComponent(GlBadge);
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findLastUpdated = () => wrapper.findByTestId('vsa-data-refresh-last');
  const findNextUpdate = () => wrapper.findByTestId('vsa-data-refresh-next');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default state', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders the elapsed time badge', () => {
      expect(findBadge().exists()).toBe(true);
      expect(findBadge().text()).toContain('Last updated about 1 hour ago');
    });

    it('renders the data refresh popover', () => {
      expect(findPopover().exists()).toBe(true);
      expect(findPopover().attributes('title')).toBe(POPOVER_TITLE);
    });

    it('renders the last updated date in the popover', () => {
      const txt = findLastUpdated().text();
      expect(txt).toContain(LAST_UPDATED_TEXT);
      expect(txt).toContain(toYmdhs(aggregationData.lastRunAt));
    });

    it('renders the next update date in the popover', () => {
      const txt = findNextUpdate().text();
      expect(txt).toContain(NEXT_UPDATE_TEXT);
      expect(txt).toContain(toYmdhs(aggregationData.nextRunAt));
    });
  });
});
