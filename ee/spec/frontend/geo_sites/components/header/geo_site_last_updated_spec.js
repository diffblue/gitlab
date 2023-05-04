import { GlPopover, GlLink, GlIcon, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GeoSiteLastUpdated from 'ee/geo_sites/components/header/geo_site_last_updated.vue';
import {
  HELP_SITE_HEALTH_URL,
  GEO_TROUBLESHOOTING_URL,
  STATUS_DELAY_THRESHOLD_MS,
} from 'ee/geo_sites/constants';
import { differenceInMilliseconds } from '~/lib/utils/datetime_utility';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';

describe('GeoSiteLastUpdated', () => {
  let wrapper;

  // The threshold is inclusive so -1 to force stale
  const staleStatusTime = differenceInMilliseconds(STATUS_DELAY_THRESHOLD_MS) - 1;
  const nonStaleStatusTime = new Date().getTime();

  const defaultProps = {
    statusCheckTimestamp: staleStatusTime,
  };

  const createComponent = (props) => {
    wrapper = shallowMountExtended(GeoSiteLastUpdated, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: { GlSprintf },
    });
  };

  const findMainText = () => wrapper.findByTestId('last-updated-main-text');
  const findGlIcon = () => wrapper.findComponent(GlIcon);
  const findGlPopover = () => wrapper.findComponent(GlPopover);
  const findPopoverText = () => wrapper.findByTestId('geo-last-updated-text');
  const findPopoverLink = () => findGlPopover().findComponent(GlLink);

  describe('template', () => {
    describe('always', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders main text correctly', () => {
        expect(findMainText().exists()).toBe(true);
        expect(findMainText().findComponent(TimeAgo).props('time')).toBe(staleStatusTime);
      });

      it('renders the question icon correctly', () => {
        expect(findGlIcon().exists()).toBe(true);
        expect(findGlIcon().attributes('name')).toBe('question-o');
      });

      it('renders the popover', () => {
        expect(findGlPopover().exists()).toBe(true);
      });

      it('renders the popover text correctly', () => {
        expect(findPopoverText().exists()).toBe(true);
        expect(findPopoverText().findComponent(TimeAgo).props('time')).toBe(staleStatusTime);
      });

      it('renders the popover link correctly', () => {
        expect(findPopoverLink().exists()).toBe(true);
      });
    });

    it('when sync is stale popover link renders correctly', () => {
      createComponent();

      expect(findPopoverLink().text()).toBe('Consult Geo troubleshooting information');
      expect(findPopoverLink().attributes('href')).toBe(GEO_TROUBLESHOOTING_URL);
    });

    it('when sync is not stale popover link renders correctly', () => {
      createComponent({ statusCheckTimestamp: nonStaleStatusTime });

      expect(findPopoverLink().text()).toBe('Learn more about Geo site statuses');
      expect(findPopoverLink().attributes('href')).toBe(HELP_SITE_HEALTH_URL);
    });
  });
});
