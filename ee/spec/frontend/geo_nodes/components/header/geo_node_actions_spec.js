import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import GeoNodeActions from 'ee/geo_nodes/components/header/geo_node_actions.vue';
import GeoNodeActionsDesktop from 'ee/geo_nodes/components/header/geo_node_actions_desktop.vue';
import GeoNodeActionsMobile from 'ee/geo_nodes/components/header/geo_node_actions_mobile.vue';
import { REMOVE_NODE_MODAL_ID } from 'ee/geo_nodes/constants';
import { MOCK_PRIMARY_NODE } from 'ee_jest/geo_nodes/mock_data';
import waitForPromises from 'helpers/wait_for_promises';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';

Vue.use(Vuex);

describe('GeoNodeActions', () => {
  let wrapper;

  const actionSpies = {
    prepNodeRemoval: jest.fn(),
  };

  const defaultProps = {
    node: MOCK_PRIMARY_NODE,
  };

  const createComponent = (props) => {
    const store = new Vuex.Store({
      actions: actionSpies,
    });

    wrapper = shallowMount(GeoNodeActions, {
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoMobileActions = () => wrapper.findComponent(GeoNodeActionsMobile);
  const findGeoDesktopActions = () => wrapper.findComponent(GeoNodeActionsDesktop);

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

      it('preps node for removal and opens model after promise returns on desktop', async () => {
        findGeoDesktopActions().vm.$emit('remove');

        expect(actionSpies.prepNodeRemoval).toHaveBeenCalledWith(
          expect.any(Object),
          MOCK_PRIMARY_NODE.id,
        );

        expect(wrapper.vm.$root.$emit).not.toHaveBeenCalledWith(
          BV_SHOW_MODAL,
          REMOVE_NODE_MODAL_ID,
        );

        await waitForPromises();

        expect(wrapper.vm.$root.$emit).toHaveBeenCalledWith(BV_SHOW_MODAL, REMOVE_NODE_MODAL_ID);
      });

      it('preps node for removal and opens model after promise returns on mobile', async () => {
        findGeoMobileActions().vm.$emit('remove');

        expect(actionSpies.prepNodeRemoval).toHaveBeenCalledWith(
          expect.any(Object),
          MOCK_PRIMARY_NODE.id,
        );

        expect(wrapper.vm.$root.$emit).not.toHaveBeenCalledWith(
          BV_SHOW_MODAL,
          REMOVE_NODE_MODAL_ID,
        );

        await waitForPromises();

        expect(wrapper.vm.$root.$emit).toHaveBeenCalledWith(BV_SHOW_MODAL, REMOVE_NODE_MODAL_ID);
      });
    });
  });
});
