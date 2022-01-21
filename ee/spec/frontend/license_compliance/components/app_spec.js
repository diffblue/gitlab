import { GlEmptyState, GlLoadingIcon, GlTab, GlTabs, GlAlert, GlBadge } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';

import LicenseComplianceApp from 'ee/license_compliance/components/app.vue';
import DetectedLicensesTable from 'ee/license_compliance/components/detected_licenses_table.vue';
import PipelineInfo from 'ee/license_compliance/components/pipeline_info.vue';
import { REPORT_STATUS } from 'ee/license_compliance/store/modules/list/constants';

import * as getters from 'ee/license_compliance/store/modules/list/getters';

import { LICENSE_APPROVAL_CLASSIFICATION } from 'ee/vue_shared/license_compliance/constants';
import LicenseManagement from 'ee/vue_shared/license_compliance/license_management.vue';
import {
  approvedLicense,
  blacklistedLicense,
} from 'ee_jest/vue_shared/license_compliance/mock_data';
import setWindowLocation from 'helpers/set_window_location_helper';
import { stubTransition } from 'helpers/stub_transition';
import { TEST_HOST } from 'helpers/test_constants';
import SbomBanner from 'ee/sbom_banner/components/app.vue';

Vue.use(Vuex);

let wrapper;

const readLicensePoliciesEndpoint = `${TEST_HOST}/license_management`;
const managedLicenses = [approvedLicense, blacklistedLicense];
const licenses = [{}, {}];
const emptyStateSvgPath = '/';
const documentationPath = '/';
const sbomSurveySvgPath = '/';

const noop = () => {};

const createComponent = ({ state, props, options }) => {
  const fakeStore = new Vuex.Store({
    modules: {
      licenseManagement: {
        namespaced: true,
        state: {
          managedLicenses,
        },
        getters: {
          isAddingNewLicense: () => false,
          hasPendingLicenses: () => false,
          isLicenseBeingUpdated: () => () => false,
        },
        actions: {
          fetchManagedLicenses: noop,
          setLicenseApproval: noop,
        },
      },
      licenseList: {
        namespaced: true,
        state: {
          licenses,
          reportInfo: {
            jobPath: '/',
            generatedAt: '',
          },
          ...state,
        },
        actions: {
          fetchLicenses: noop,
        },
        getters,
      },
    },
  });

  const mountFunc = options && options.mount ? mount : shallowMount;

  wrapper = mountFunc(LicenseComplianceApp, {
    propsData: {
      readLicensePoliciesEndpoint,
      ...props,
    },
    ...options,
    store: fakeStore,
    stubs: { transition: stubTransition() },
    provide: {
      sbomSurveySvgPath,
      emptyStateSvgPath,
      documentationPath,
    },
  });
};

const findByTestId = (testId) => wrapper.find(`[data-testid="${testId}"]`);
const findSbomBanner = () => wrapper.findComponent(SbomBanner);

describe('Project Licenses', () => {
  beforeEach(() => {
    window.gon = {
      features: {
        sbomSurvey: true,
      },
    };
  });

  afterEach(() => {
    window.gon = {};
    wrapper.destroy();
    wrapper = null;
  });

  describe('when loading', () => {
    beforeEach(() => {
      createComponent({
        state: { initialized: false },
      });
    });

    it('shows the loading component', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });

    it('does not show the empty state component', () => {
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(false);
    });

    it('does not show the list of detected in project licenses', () => {
      expect(wrapper.findComponent(DetectedLicensesTable).exists()).toBe(false);
    });

    it('does not show the list of license policies', () => {
      expect(wrapper.findComponent(LicenseManagement).exists()).toBe(false);
    });

    it('does not render any tabs', () => {
      expect(wrapper.findComponent(GlTabs).exists()).toBe(false);
      expect(wrapper.findComponent(GlTab).exists()).toBe(false);
    });
  });

  describe('when empty state', () => {
    beforeEach(() => {
      createComponent({
        state: {
          initialized: true,
          reportInfo: {
            jobPath: '/',
            generatedAt: '',
            status: REPORT_STATUS.jobNotSetUp,
          },
        },
      });
    });

    it('shows the empty state component', () => {
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(true);
    });

    it('does not show the loading component', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
    });

    it('does not show the list of detected in project licenses', () => {
      expect(wrapper.findComponent(DetectedLicensesTable).exists()).toBe(false);
    });

    it('does not show the list of license policies', () => {
      expect(wrapper.findComponent(LicenseManagement).exists()).toBe(false);
    });

    it('does not render any tabs', () => {
      expect(wrapper.findComponent(GlTabs).exists()).toBe(false);
      expect(wrapper.findComponent(GlTab).exists()).toBe(false);
    });
  });

  describe('when page is shown', () => {
    beforeEach(() => {
      createComponent({
        state: {
          initialized: true,
          reportInfo: {
            jobPath: '/',
            generatedAt: '',
            status: REPORT_STATUS.ok,
          },
        },
      });
    });

    it('does not render a policy violations alert', () => {
      expect(wrapper.findComponent(GlAlert).exists()).toBe(false);
    });

    it('renders the SbomBannercomponent with the right props', () => {
      const sbomBanner = findSbomBanner();
      expect(sbomBanner.exists()).toBe(true);
      expect(sbomBanner.props().sbomSurveySvgPath).toEqual(sbomSurveySvgPath);
    });

    it('renders a "Detected in project" tab and a "Policies" tab', () => {
      expect(wrapper.findComponent(GlTabs).exists()).toBe(true);
      expect(wrapper.findComponent(GlTab).exists()).toBe(true);
      expect(wrapper.findAllComponents(GlTab)).toHaveLength(2);
    });

    it('it renders the "Detected in project" table', () => {
      expect(wrapper.findComponent(DetectedLicensesTable).exists()).toBe(true);
    });

    it('it renders the "Policies" table', () => {
      expect(wrapper.findComponent(LicenseManagement).exists()).toBe(true);
    });

    it('renders the pipeline info', () => {
      expect(wrapper.findComponent(PipelineInfo).exists()).toBe(true);
    });

    describe.each`
      givenLocationHash | expectedActiveTab
      ${'#licenses'}    | ${'licenses'}
      ${'#policies'}    | ${'policies'}
    `(
      'when window.location contains the hash "$givenLocationHash"',
      ({ givenLocationHash, expectedActiveTab }) => {
        const originalLocation = window.location.href;

        beforeEach(() => {
          setWindowLocation(`http://foo.com/index${givenLocationHash}`);

          createComponent({
            state: {
              initialized: true,
              isLoading: false,
              licenses: [
                {
                  name: 'MIT',
                  classification: LICENSE_APPROVAL_CLASSIFICATION.DENIED,
                  components: [],
                },
              ],
              pageInfo: 1,
            },
            options: {
              mount: true,
            },
          });
        });

        afterEach(() => {
          setWindowLocation(originalLocation);
        });

        it(`sets the active tab to be "${expectedActiveTab}"`, () => {
          expect(findByTestId(`${expectedActiveTab}Tab`).classes()).toContain('active');
        });
      },
    );

    describe('when the tabs are rendered', () => {
      const pageInfo = {
        total: 1,
      };

      beforeEach(() => {
        createComponent({
          state: {
            initialized: true,
            isLoading: false,
            licenses: [
              {
                name: 'MIT',
                classification: LICENSE_APPROVAL_CLASSIFICATION.DENIED,
                components: [],
              },
            ],
            reportInfo: {
              jobPath: '/',
              generatedAt: '',
              status: REPORT_STATUS.ok,
            },
            pageInfo,
          },
          options: {
            mount: true,
          },
        });
      });

      it.each`
        givenActiveTab | expectedLocationHash
        ${'policies'}  | ${'#policies'}
        ${'licenses'}  | ${'#licenses'}
      `(
        'sets the location hash to "$expectedLocationHash" when the "$givenTab" tab is activate',
        ({ givenActiveTab, expectedLocationHash }) => {
          findByTestId(`${givenActiveTab}TabTitle`).trigger('click');

          return wrapper.vm.$nextTick().then(() => {
            expect(window.location.hash).toBe(expectedLocationHash);
          });
        },
      );

      it('it renders the correct count in "Detected in project" tab', () => {
        expect(wrapper.findAllComponents(GlBadge).at(0).text()).toBe(pageInfo.total.toString());
      });

      it('it renders the correct count in "Policies" tab', () => {
        expect(wrapper.findAllComponents(GlBadge).at(1).text()).toBe(
          managedLicenses.length.toString(),
        );
      });

      it('it renders the correct type of badge styling', () => {
        const badges = [
          wrapper.findAllComponents(GlBadge).at(0),
          wrapper.findAllComponents(GlBadge).at(1),
        ];
        badges.forEach((badge) => expect(badge.classes()).toContain('gl-tab-counter-badge'));
      });
    });

    describe('when there are policy violations', () => {
      beforeEach(() => {
        createComponent({
          state: {
            initialized: true,
            licenses: [{ classification: LICENSE_APPROVAL_CLASSIFICATION.DENIED }],
          },
        });
      });

      it('renders a policy violations alert', () => {
        expect(wrapper.findComponent(GlAlert).exists()).toBe(true);
        expect(wrapper.findComponent(GlAlert).text()).toContain(
          "Detected licenses that are out-of-compliance with the project's assigned policies",
        );
      });
    });
  });
});
