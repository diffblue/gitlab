import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import GeoNodeActionsDesktop from 'ee/geo_nodes/components/header/geo_node_actions_desktop.vue';
import { MOCK_NODES } from 'ee_jest/geo_nodes/mock_data';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

Vue.use(Vuex);

describe('GeoNodeActionsDesktop', () => {
  let wrapper;

  const defaultProps = {
    node: MOCK_NODES[0],
  };

  const createComponent = (props, getters) => {
    const store = new Vuex.Store({
      getters: {
        canRemoveNode: () => () => true,
        ...getters,
      },
    });

    wrapper = extendedWrapper(
      shallowMount(GeoNodeActionsDesktop, {
        store,
        propsData: {
          ...defaultProps,
          ...props,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoDesktopActionsButtons = () => wrapper.findAllComponents(GlButton);
  const findGeoDesktopActionsEditButton = () => wrapper.findByTestId('geo-desktop-edit-action');
  const findGeoDesktopActionsRemoveButton = () => wrapper.findByTestId('geo-desktop-remove-action');

  describe('template', () => {
    describe('always', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders an Edit and Remove button icon', () => {
        expect(
          findGeoDesktopActionsButtons().wrappers.map((w) => w.attributes('icon')),
        ).toStrictEqual(['pencil', 'remove']);
      });

      it('renders edit link correctly', () => {
        expect(findGeoDesktopActionsButtons().at(0).attributes('href')).toBe(
          MOCK_NODES[0].webEditUrl,
        );
      });

      it('emits remove when remove button is clicked', () => {
        findGeoDesktopActionsRemoveButton().vm.$emit('click');

        expect(wrapper.emitted('remove')).toHaveLength(1);
      });
    });

    describe.each`
      canRemoveNode | disabled
      ${false}      | ${'true'}
      ${true}       | ${undefined}
    `(`conditionally`, ({ canRemoveNode, disabled }) => {
      beforeEach(() => {
        createComponent({}, { canRemoveNode: () => () => canRemoveNode });
      });

      describe(`when canRemoveNode is ${canRemoveNode}`, () => {
        it(`does ${canRemoveNode ? 'not ' : ''}disable the Desktop Remove button`, () => {
          expect(findGeoDesktopActionsRemoveButton().attributes('disabled')).toBe(disabled);
        });
      });
    });

    describe.each`
      primary  | editTooltip              | removeTooltip
      ${false} | ${'Edit secondary site'} | ${'Remove secondary site'}
      ${true}  | ${'Edit primary site'}   | ${'Remove primary site'}
    `('action tooltips', ({ primary, editTooltip, removeTooltip }) => {
      describe(`when node is ${primary ? '' : ' not'} a primary node`, () => {
        beforeEach(() => {
          createComponent({ node: { ...MOCK_NODES[0], primary } });
        });

        it(`sets edit tooltip to ${editTooltip}`, () => {
          expect(findGeoDesktopActionsEditButton().attributes('title')).toBe(editTooltip);
          expect(findGeoDesktopActionsEditButton().attributes('aria-label')).toBe(editTooltip);
        });

        it(`sets remove tooltip to ${removeTooltip}`, () => {
          expect(findGeoDesktopActionsRemoveButton().attributes('title')).toBe(removeTooltip);
          expect(findGeoDesktopActionsRemoveButton().attributes('aria-label')).toBe(removeTooltip);
        });
      });
    });
  });
});
