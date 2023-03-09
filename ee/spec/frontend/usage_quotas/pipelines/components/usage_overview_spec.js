import { GlLink, GlProgressBar } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import UsageOverview from 'ee/usage_quotas/pipelines/components/usage_overview.vue';
import { defaultProvide, defaultUsageOverviewProps } from '../mock_data';

describe('UsageOverview', () => {
  let wrapper;

  const createComponent = ({ provide = {}, props = {} } = {}) => {
    wrapper = shallowMountExtended(UsageOverview, {
      propsData: {
        ...defaultUsageOverviewProps,
        ...props,
      },
      provide: {
        ...defaultProvide,
        ...provide,
      },
    });
  };

  const findMinutesTitle = () => wrapper.findByTestId('minutes-title');
  const findMinutesUsed = () => wrapper.findByTestId('minutes-used');
  const findMinutesUsedPercentage = () => wrapper.findByTestId('minutes-used-percentage');
  const findHelpLink = () => wrapper.findComponent(GlLink);
  const findGlProgressBar = () => wrapper.findComponent(GlProgressBar);

  beforeEach(() => {
    createComponent();
  });

  it('renders the minutes title properly', () => {
    expect(findMinutesTitle().text()).toBe(defaultUsageOverviewProps.minutesTitle);
  });

  it('renders the minutes used properly', () => {
    expect(findMinutesUsed().text()).toBe(defaultUsageOverviewProps.minutesUsed);
  });

  it('passes the correct data to the help link', () => {
    expect(findHelpLink().attributes()).toMatchObject({
      'aria-label': defaultUsageOverviewProps.helpLinkLabel,
      href: defaultUsageOverviewProps.helpLinkHref,
    });
  });

  it('renders the minutes used percentage properly', () => {
    expect(findMinutesUsedPercentage().text()).toBe(
      defaultUsageOverviewProps.minutesUsedPercentage,
    );
  });

  it('passess the correct props to GlProgressBar', () => {
    expect(findGlProgressBar().attributes()).toMatchObject({
      value: defaultUsageOverviewProps.minutesUsedPercentage,
      variant: 'success',
    });
  });
});
