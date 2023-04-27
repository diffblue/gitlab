import { GlTab } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import BasePipelineTabs from '~/pipelines/components/pipeline_tabs.vue';
import PipelineTabs from 'ee/pipelines/components/pipeline_tabs.vue';
import CodequalityReportApp from 'ee/codequality_report/codequality_report.vue';

describe('The Pipeline Tabs', () => {
  let wrapper;

  const findCodeQualityTab = () => wrapper.findByTestId('code-quality-tab');
  const findDagTab = () => wrapper.findByTestId('dag-tab');
  const findFailedJobsTab = () => wrapper.findByTestId('failed-jobs-tab');
  const findJobsTab = () => wrapper.findByTestId('jobs-tab');
  const findLicenseTab = () => wrapper.findByTestId('license-tab');
  const findPipelineTab = () => wrapper.findByTestId('pipeline-tab');
  const findSecurityTab = () => wrapper.findByTestId('security-tab');
  const findTestsTab = () => wrapper.findByTestId('tests-tab');
  const getLicenseCount = () => wrapper.findByTestId('license-counter').text();
  const getCodequalityCount = () => wrapper.findByTestId('codequality-counter');
  const findCodeQualityRouterView = () => wrapper.findComponent({ ref: 'router-view-codequality' });
  const findLicensesRouterView = () => wrapper.findComponent({ ref: 'router-view-licenses' });

  const defaultProvide = {
    canGenerateCodequalityReports: false,
    canManageLicenses: true,
    codequalityReportDownloadPath: '',
    defaultTabValue: '',
    exposeSecurityDashboard: false,
    exposeLicenseScanningData: false,
    failedJobsCount: 1,
    failedJobsSummary: [],
    isFullCodequalityReportAvailable: true,
    licenseManagementApiUrl: '/path/to/license_management_api_url',
    licensesApiPath: '/path/to/licenses_api',
    securityPoliciesPath: '/path/to/-/security/policies',
    licenseScanCount: 11,
    pipelineIid: '100',
    totalJobCount: 10,
    testsCount: 123,
  };

  const createComponent = ({ propsData = {}, provide = {}, stubs = {} } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(PipelineTabs, {
        propsData,
        provide: {
          ...defaultProvide,
          ...provide,
        },
        stubs: {
          BasePipelineTabs,
          RouterView: true,
          ...stubs,
        },
      }),
    );
  };

  it('lazy loads all tabs', () => {
    createComponent({
      stubs: {
        GlTab,
      },
    });
    const tabs = wrapper.findAllComponents(GlTab);

    tabs.wrappers.forEach((tab) => {
      expect(tab.attributes('lazy')).toBe('true');
    });
  });

  describe('CE Tabs', () => {
    it.each`
      tabName          | tabComponent
      ${'Pipeline'}    | ${findPipelineTab}
      ${'Dag'}         | ${findDagTab}
      ${'Jobs'}        | ${findJobsTab}
      ${'Failed Jobs'} | ${findFailedJobsTab}
      ${'Tests'}       | ${findTestsTab}
    `('shows $tabName tab with its associated component', ({ tabComponent }) => {
      createComponent();

      expect(tabComponent().exists()).toBe(true);
    });

    describe('with no failed jobs', () => {
      beforeEach(() => {
        createComponent({
          provide: { failedJobsCount: 0 },
        });
      });

      it('hides the failed jobs tab', () => {
        expect(findFailedJobsTab().exists()).toBe(false);
      });
    });
  });

  describe('EE Tabs', () => {
    describe('visibility', () => {
      it.each`
        tabName       | tabComponent       | provideKey                     | isVisible | text
        ${'Security'} | ${findSecurityTab} | ${'exposeSecurityDashboard'}   | ${true}   | ${'shows'}
        ${'Security'} | ${findSecurityTab} | ${'exposeSecurityDashboard'}   | ${false}  | ${'hides'}
        ${'License'}  | ${findLicenseTab}  | ${'exposeLicenseScanningData'} | ${true}   | ${'shows'}
        ${'License'}  | ${findLicenseTab}  | ${'exposeLicenseScanningData'} | ${false}  | ${'hides'}
      `(
        '$text $tabName tab when $provideKey is $provideKey',
        ({ tabComponent, provideKey, isVisible }) => {
          createComponent({
            provide: { [provideKey]: isVisible },
          });
          expect(tabComponent().exists()).toBe(isVisible);
        },
      );
    });

    it.each`
      canGenerate | isVisible | codequalityReportDownloadPath | isReportAvailable | text
      ${true}     | ${true}   | ${''}                         | ${true}           | ${'shows'}
      ${false}    | ${false}  | ${''}                         | ${true}           | ${'hides'}
      ${false}    | ${true}   | ${'/path'}                    | ${true}           | ${'shows'}
      ${true}     | ${true}   | ${'/path'}                    | ${true}           | ${'shows'}
      ${true}     | ${false}  | ${'/path'}                    | ${false}          | ${'hides'}
    `(
      '$text Code Quality tab when canGenerateCodequalityReports is $canGenerate and codequalityReportDownloadPath is $codequalityReportDownloadPath',
      ({ canGenerate, isReportAvailable, isVisible, codequalityReportDownloadPath }) => {
        createComponent({
          provide: {
            isFullCodequalityReportAvailable: isReportAvailable,
            canGenerateCodequalityReports: canGenerate,
            codequalityReportDownloadPath,
          },
        });
        expect(findCodeQualityTab().exists()).toBe(isVisible);
      },
    );
  });

  describe('codequality badge count', () => {
    beforeEach(() => {
      createComponent({
        provide: {
          isFullCodequalityReportAvailable: true,
          canGenerateCodequalityReports: true,
          codequalityReportDownloadPath: '/dsda',
        },
        stubs: { GlTab, CodequalityReportApp },
      });
    });

    it('updates the codequality badge after a new count has been emitted', async () => {
      const newLicenseCount = 100;
      expect(getCodequalityCount().exists()).toBe(false);

      findCodeQualityRouterView().vm.$emit('updateBadgeCount', newLicenseCount);
      await nextTick();

      expect(getCodequalityCount().text()).toBe(`${newLicenseCount}`);
    });

    it('shows the correct codequality badge when the count is 0', async () => {
      const newLicenseCount = 0;
      findCodeQualityRouterView().vm.$emit('updateBadgeCount', newLicenseCount);
      await nextTick();

      expect(getCodequalityCount().text()).toBe(`${newLicenseCount}`);
    });
  });

  describe('license compliance', () => {
    beforeEach(() => {
      createComponent({
        provide: { exposeLicenseScanningData: true },
        stubs: { GlTab },
      });
    });

    it('passes down all props to the license app', () => {
      expect(findLicensesRouterView().attributes()).toMatchObject({
        'api-url': defaultProvide.licenseManagementApiUrl,
        'licenses-api-path': defaultProvide.licensesApiPath,
        'security-policies-path': defaultProvide.securityPoliciesPath,
        'can-manage-licenses': defaultProvide.canManageLicenses.toString(),
        'always-open': 'true',
      });
    });

    it('sets the initial count and updates the license count badge after a new count has been emitted', async () => {
      const newLicenseCount = 100;

      expect(getLicenseCount()).toBe('11');

      findLicensesRouterView().vm.$emit('updateBadgeCount', newLicenseCount);
      await nextTick();

      expect(getLicenseCount()).toBe(`${newLicenseCount}`);
    });
  });
});
