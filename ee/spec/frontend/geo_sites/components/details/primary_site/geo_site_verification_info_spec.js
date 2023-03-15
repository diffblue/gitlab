import { GlCard, GlIcon, GlPopover, GlLink } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GeoSiteProgressBar from 'ee/geo_sites/components/details/geo_site_progress_bar.vue';
import GeoSiteVerificationInfo from 'ee/geo_sites/components/details/primary_site/geo_site_verification_info.vue';
import { HELP_INFO_URL } from 'ee/geo_sites/constants';
import { MOCK_PRIMARY_SITE, MOCK_PRIMARY_VERIFICATION_INFO } from 'ee_jest/geo_sites/mock_data';

Vue.use(Vuex);

describe('GeoSiteVerificationInfo', () => {
  let wrapper;

  const defaultProps = {
    site: MOCK_PRIMARY_SITE,
  };

  const createComponent = (props) => {
    const store = new Vuex.Store({
      getters: {
        verificationInfo: () => () => MOCK_PRIMARY_VERIFICATION_INFO,
      },
    });

    wrapper = shallowMountExtended(GeoSiteVerificationInfo, {
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: { GlCard },
    });
  };

  const findGlCard = () => wrapper.findComponent(GlCard);
  const findGlIcon = () => wrapper.findComponent(GlIcon);
  const findGlPopover = () => wrapper.findComponent(GlPopover);
  const findGlPopoverLink = () => findGlPopover().findComponent(GlLink);
  const findGeoSiteProgressBarTitles = () => wrapper.findAllByTestId('verification-bar-title');
  const findGeoSiteProgressBars = () => wrapper.findAllComponents(GeoSiteProgressBar);

  describe('template', () => {
    describe('always', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the details card', () => {
        expect(findGlCard().exists()).toBe(true);
      });

      it('renders the question icon correctly', () => {
        expect(findGlIcon().exists()).toBe(true);
        expect(findGlIcon().props('name')).toBe('question-o');
      });

      it('renders the GlPopover always', () => {
        expect(findGlPopover().exists()).toBe(true);
      });

      it('renders the popover link correctly', () => {
        expect(findGlPopoverLink().exists()).toBe(true);
        expect(findGlPopoverLink().attributes('href')).toBe(HELP_INFO_URL);
      });

      it('renders a progress bar for each verification replicable', () => {
        expect(findGeoSiteProgressBars()).toHaveLength(MOCK_PRIMARY_VERIFICATION_INFO.length);
      });

      it('renders progress bar titles correctly', () => {
        expect(findGeoSiteProgressBarTitles().wrappers.map((w) => w.text())).toStrictEqual(
          MOCK_PRIMARY_VERIFICATION_INFO.map((vI) => `${vI.title} checksum progress`),
        );
      });
    });
  });
});
