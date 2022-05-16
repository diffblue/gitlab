import { GlCard, GlIcon, GlPopover, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import GeoNodeProgressBar from 'ee/geo_nodes/components/details/geo_node_progress_bar.vue';
import GeoNodeVerificationInfo from 'ee/geo_nodes/components/details/primary_node/geo_node_verification_info.vue';
import { HELP_INFO_URL } from 'ee/geo_nodes/constants';
import { MOCK_PRIMARY_NODE, MOCK_PRIMARY_VERIFICATION_INFO } from 'ee_jest/geo_nodes/mock_data';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

Vue.use(Vuex);

describe('GeoNodeVerificationInfo', () => {
  let wrapper;

  const defaultProps = {
    node: MOCK_PRIMARY_NODE,
  };

  const createComponent = (props) => {
    const store = new Vuex.Store({
      getters: {
        verificationInfo: () => () => MOCK_PRIMARY_VERIFICATION_INFO,
      },
    });

    wrapper = extendedWrapper(
      shallowMount(GeoNodeVerificationInfo, {
        store,
        propsData: {
          ...defaultProps,
          ...props,
        },
        stubs: { GlCard },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGlCard = () => wrapper.findComponent(GlCard);
  const findGlIcon = () => wrapper.findComponent(GlIcon);
  const findGlPopover = () => wrapper.findComponent(GlPopover);
  const findGlPopoverLink = () => findGlPopover().findComponent(GlLink);
  const findGeoNodeProgressBarTitles = () => wrapper.findAllByTestId('verification-bar-title');
  const findGeoNodeProgressBars = () => wrapper.findAllComponents(GeoNodeProgressBar);

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
        expect(findGeoNodeProgressBars()).toHaveLength(MOCK_PRIMARY_VERIFICATION_INFO.length);
      });

      it('renders progress bar titles correctly', () => {
        expect(findGeoNodeProgressBarTitles().wrappers.map((w) => w.text())).toStrictEqual(
          MOCK_PRIMARY_VERIFICATION_INFO.map((vI) => `${vI.title} checksum progress`),
        );
      });
    });
  });
});
