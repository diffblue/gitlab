import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import GeoSiteActions from 'ee/geo_sites/components/header/geo_site_actions.vue';
import GeoSiteActionsDesktop from 'ee/geo_sites/components/header/geo_site_actions_desktop.vue';
import GeoSiteActionsMobile from 'ee/geo_sites/components/header/geo_site_actions_mobile.vue';
import { REMOVE_SITE_MODAL_ID } from 'ee/geo_sites/constants';
import { MOCK_PRIMARY_SITE } from 'ee_jest/geo_sites/mock_data';
import waitForPromises from 'helpers/wait_for_promises';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';

Vue.use(Vuex);

describe('GeoSiteActions', () => {
  let wrapper;

  const actionSpies = {
    prepSiteRemoval: jest.fn(),
  };

  const defaultProps = {
    site: MOCK_PRIMARY_SITE,
  };

  const createComponent = (props) => {
    const store = new Vuex.Store({
      actions: actionSpies,
    });

    wrapper = shallowMount(GeoSiteActions, {
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findGeoMobileActions = () => wrapper.findComponent(GeoSiteActionsMobile);
  const findGeoDesktopActions = () => wrapper.findComponent(GeoSiteActionsDesktop);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders mobile actions with correct visibility class always', () => {
      expect(findGeoMobileActions().exists()).toBe(true);
      expect(findGeoMobileActions().classes()).toStrictEqual(['gl-lg-display-none']);
    });

    it('renders desktop actions with correct visibility class always', () => {
      expect(findGeoDesktopActions().exists()).toBe(true);
      expect(findGeoDesktopActions().classes()).toStrictEqual([
        'gl-display-none',
        'gl-lg-display-flex',
      ]);
    });
  });

  describe('events', () => {
    describe('remove', () => {
      beforeEach(() => {
        createComponent();
        jest.spyOn(wrapper.vm.$root, '$emit');
      });

      it('preps site for removal and opens model after promise returns on desktop', async () => {
        findGeoDesktopActions().vm.$emit('remove');

        expect(actionSpies.prepSiteRemoval).toHaveBeenCalledWith(
          expect.any(Object),
          MOCK_PRIMARY_SITE.id,
        );

        expect(wrapper.vm.$root.$emit).not.toHaveBeenCalledWith(
          BV_SHOW_MODAL,
          REMOVE_SITE_MODAL_ID,
        );

        await waitForPromises();

        expect(wrapper.vm.$root.$emit).toHaveBeenCalledWith(BV_SHOW_MODAL, REMOVE_SITE_MODAL_ID);
      });

      it('preps site for removal and opens model after promise returns on mobile', async () => {
        findGeoMobileActions().vm.$emit('remove');

        expect(actionSpies.prepSiteRemoval).toHaveBeenCalledWith(
          expect.any(Object),
          MOCK_PRIMARY_SITE.id,
        );

        expect(wrapper.vm.$root.$emit).not.toHaveBeenCalledWith(
          BV_SHOW_MODAL,
          REMOVE_SITE_MODAL_ID,
        );

        await waitForPromises();

        expect(wrapper.vm.$root.$emit).toHaveBeenCalledWith(BV_SHOW_MODAL, REMOVE_SITE_MODAL_ID);
      });
    });
  });
});
