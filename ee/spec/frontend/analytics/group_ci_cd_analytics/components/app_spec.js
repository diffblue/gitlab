import { GlTabs, GlTab, GlLink } from '@gitlab/ui';
import { merge } from 'lodash';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CiCdAnalyticsApp from 'ee/analytics/group_ci_cd_analytics/components/app.vue';
import ReleaseStatsCard from 'ee/analytics/group_ci_cd_analytics/components/release_stats_card.vue';
import DeploymentFrequencyCharts from 'ee/dora/components/deployment_frequency_charts.vue';
import LeadTimeCharts from 'ee/dora/components/lead_time_charts.vue';
import TimeToRestoreServiceCharts from 'ee/dora/components/time_to_restore_service_charts.vue';
import ChangeFailureRateCharts from 'ee/dora/components/change_failure_rate_charts.vue';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';
import { getParameterValues } from '~/lib/utils/url_utility';
import API from '~/api';

jest.mock('~/lib/utils/url_utility');

describe('ee/analytics/group_ci_cd_analytics/components/app.vue', () => {
  let wrapper;

  beforeEach(() => {
    getParameterValues.mockReturnValue([]);
  });

  const quotaPath = '/groups/my-awesome-group/-/usage_quotas#pipelines-quota-tab';

  const createComponent = (mountOptions = {}, canView = true) => {
    wrapper = shallowMountExtended(
      CiCdAnalyticsApp,
      merge(
        {
          provide: {
            shouldRenderDoraCharts: true,
            pipelineGroupUsageQuotaPath: quotaPath,
            canViewGroupUsageQuotaBoolean: canView,
          },
        },
        mountOptions,
      ),
    );
  };

  const findGlTabs = () => wrapper.findComponent(GlTabs);
  const findUsageQuotaLink = () => wrapper.findComponent(GlLink);
  const findAllGlTabs = () => wrapper.findAllComponents(GlTab);
  const findGlTabAtIndex = (index) => findAllGlTabs().at(index);

  describe('tabs', () => {
    describe('when the DORA charts are available', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders tabs in the correct order', () => {
        [
          'Release statistics',
          'Deployment frequency',
          'Lead time',
          'Time to restore service',
          'Change failure rate',
        ].forEach((tabName, index) => {
          expect(findGlTabAtIndex(index).attributes('title')).toBe(tabName);
        });
      });

      describe('event tracking', () => {
        [
          'release statistics',
          'deployment frequency',
          'lead time',
          'time to restore service',
          'change failure rate',
        ].forEach((tabName) => {
          it(`tracks visits to ${tabName} tab`, () => {
            const testId = `${tabName.replace(/\s/g, '-')}-tab`;
            const eventName = `g_analytics_ci_cd_${tabName.replace(/\s/g, '_')}`;

            jest.spyOn(API, 'trackRedisHllUserEvent');

            expect(API.trackRedisHllUserEvent).not.toHaveBeenCalled();

            wrapper.findByTestId(testId).vm.$emit('click');

            expect(API.trackRedisHllUserEvent).toHaveBeenCalledWith(eventName);
          });
        });
      });
    });

    describe('when the DORA charts are not available', () => {
      beforeEach(() => {
        createComponent({ provide: { shouldRenderDoraCharts: false } });
      });

      it('renders the release statistics component', () => {
        expect(wrapper.findComponent(ReleaseStatsCard).exists()).toBe(true);
      });

      it('does not render the DORA chart components', () => {
        expect(wrapper.findComponent(DeploymentFrequencyCharts).exists()).toBe(false);
        expect(wrapper.findComponent(LeadTimeCharts).exists()).toBe(false);
        expect(wrapper.findComponent(TimeToRestoreServiceCharts).exists()).toBe(false);
        expect(wrapper.findComponent(ChangeFailureRateCharts).exists()).toBe(false);
      });
    });
  });

  describe('release statistics', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the release statistics component inside the first tab', () => {
      expect(findGlTabAtIndex(0).findComponent(ReleaseStatsCard).exists()).toBe(true);
    });
  });

  describe('deployment frequency', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the deployment frequency component inside the second tab', () => {
      expect(findGlTabAtIndex(1).findComponent(DeploymentFrequencyCharts).exists()).toBe(true);
    });
  });

  describe('lead time', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the lead time component inside the third tab', () => {
      expect(findGlTabAtIndex(2).findComponent(LeadTimeCharts).exists()).toBe(true);
    });
  });

  describe('time to restore service', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the time to restore service component inside the fourth tab', () => {
      expect(findGlTabAtIndex(3).findComponent(TimeToRestoreServiceCharts).exists()).toBe(true);
    });
  });

  describe('change failure rate', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the change failure rate inside the fifth tab', () => {
      expect(findGlTabAtIndex(4).findComponent(ChangeFailureRateCharts).exists()).toBe(true);
    });
  });

  describe('when provided with a query param', () => {
    it.each`
      tab                          | index
      ${'release-statistics'}      | ${'0'}
      ${'deployment-frequency'}    | ${'1'}
      ${'lead-time'}               | ${'2'}
      ${'time-to-restore-service'} | ${'3'}
      ${'change-failure-rate'}     | ${'4'}
      ${'fake'}                    | ${'0'}
      ${''}                        | ${'0'}
    `('shows the correct tab for URL parameter "$tab"', ({ tab, index }) => {
      setWindowLocation(`${TEST_HOST}/groups/gitlab-org/gitlab/-/analytics/ci_cd?tab=${tab}`);
      getParameterValues.mockImplementation((name) => {
        expect(name).toBe('tab');
        return tab ? [tab] : [];
      });
      createComponent();
      expect(findGlTabs().attributes('value')).toBe(index);
    });
  });

  it('displays link to group pipeline usage quota page', () => {
    createComponent({
      stubs: {
        GlTabs: {
          template: '<div><slot></slot><slot name="tabs-end"></slot></div>',
        },
      },
    });

    expect(findUsageQuotaLink().attributes('href')).toBe(quotaPath);
    expect(findUsageQuotaLink().text()).toBe('View group pipeline usage quota');
  });

  it('hides link to group pipelines usage quota page based on permissions', () => {
    createComponent(
      {
        stubs: {
          GlTabs: {
            template: '<div><slot></slot><slot name="tabs-end"></slot></div>',
          },
        },
      },
      false,
    );

    expect(findUsageQuotaLink().exists()).toBe(false);
  });
});
