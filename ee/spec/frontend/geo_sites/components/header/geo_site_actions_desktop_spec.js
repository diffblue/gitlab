import { GlButton } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GeoSiteActionsDesktop from 'ee/geo_sites/components/header/geo_site_actions_desktop.vue';
import { MOCK_PRIMARY_SITE } from 'ee_jest/geo_sites/mock_data';

Vue.use(Vuex);

describe('GeoSiteActionsDesktop', () => {
  let wrapper;

  const defaultProps = {
    site: MOCK_PRIMARY_SITE,
  };

  const createComponent = (props, getters) => {
    const store = new Vuex.Store({
      getters: {
        canRemoveSite: () => () => true,
        ...getters,
      },
    });

    wrapper = shallowMountExtended(GeoSiteActionsDesktop, {
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

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
          MOCK_PRIMARY_SITE.webEditUrl,
        );
      });

      it('emits remove when remove button is clicked', () => {
        findGeoDesktopActionsRemoveButton().vm.$emit('click');

        expect(wrapper.emitted('remove')).toHaveLength(1);
      });
    });

    describe.each`
      canRemoveSite | disabled
      ${false}      | ${'true'}
      ${true}       | ${undefined}
    `(`conditionally`, ({ canRemoveSite, disabled }) => {
      beforeEach(() => {
        createComponent({}, { canRemoveSite: () => () => canRemoveSite });
      });

      describe(`when canRemoveSite is ${canRemoveSite}`, () => {
        it(`does ${canRemoveSite ? 'not ' : ''}disable the Desktop Remove button`, () => {
          expect(findGeoDesktopActionsRemoveButton().attributes('disabled')).toBe(disabled);
        });
      });
    });

    describe.each`
      primary  | editTooltip              | removeTooltip
      ${false} | ${'Edit secondary site'} | ${'Remove secondary site'}
      ${true}  | ${'Edit primary site'}   | ${'Remove primary site'}
    `('action tooltips', ({ primary, editTooltip, removeTooltip }) => {
      describe(`when site is ${primary ? '' : ' not'} a primary site`, () => {
        beforeEach(() => {
          createComponent({ site: { ...MOCK_PRIMARY_SITE, primary } });
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
