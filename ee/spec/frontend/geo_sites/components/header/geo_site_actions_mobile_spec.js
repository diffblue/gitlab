import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GeoSiteActionsMobile from 'ee/geo_sites/components/header/geo_site_actions_mobile.vue';
import { MOCK_PRIMARY_SITE } from 'ee_jest/geo_sites/mock_data';

Vue.use(Vuex);

describe('GeoSiteActionsMobile', () => {
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

    wrapper = shallowMountExtended(GeoSiteActionsMobile, {
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findGeoMobileActionsDropdown = () => wrapper.findComponent(GlDropdown);
  const findGeoMobileActionsDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findGeoMobileActionsRemoveDropdownItem = () =>
    wrapper.findByTestId('geo-mobile-remove-action');
  const findGeoMobileActionsRemoveDropdownItemText = () => wrapper.findByText('Remove');

  describe('template', () => {
    describe('always', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders Dropdown', () => {
        expect(findGeoMobileActionsDropdown().exists()).toBe(true);
      });

      it('renders an Edit and Remove dropdown item', () => {
        expect(findGeoMobileActionsDropdownItems().wrappers.map((w) => w.text())).toStrictEqual([
          'Edit',
          'Remove',
        ]);
      });

      it('renders edit link correctly', () => {
        expect(findGeoMobileActionsDropdownItems().at(0).attributes('href')).toBe(
          MOCK_PRIMARY_SITE.webEditUrl,
        );
      });

      it('emits remove when remove button is clicked', () => {
        findGeoMobileActionsRemoveDropdownItem().vm.$emit('click');

        expect(wrapper.emitted('remove')).toHaveLength(1);
      });
    });

    describe.each`
      canRemoveSite | disabled     | dropdownClass
      ${false}      | ${'true'}    | ${'gl-text-gray-400'}
      ${true}       | ${undefined} | ${'gl-text-red-500'}
    `(`conditionally`, ({ canRemoveSite, disabled, dropdownClass }) => {
      beforeEach(() => {
        createComponent({}, { canRemoveSite: () => () => canRemoveSite });
      });

      describe(`when canRemoveSite is ${canRemoveSite}`, () => {
        it(`does ${
          canRemoveSite ? 'not ' : ''
        }disable the Mobile Remove dropdown item and adds proper class`, () => {
          expect(findGeoMobileActionsRemoveDropdownItem().attributes('disabled')).toBe(disabled);
          expect(findGeoMobileActionsRemoveDropdownItemText().classes(dropdownClass)).toBe(true);
        });
      });
    });
  });
});
