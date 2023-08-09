import { mount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import GeoSiteFormCore from 'ee/geo_site_form/components/geo_site_form_core.vue';
import { VALIDATION_FIELD_KEYS } from 'ee/geo_site_form/constants';
import { MOCK_SITE, STRING_OVER_255 } from '../mock_data';

Vue.use(Vuex);

describe('GeoSiteFormCore', () => {
  let wrapper;
  let store;

  const defaultProps = {
    siteData: MOCK_SITE,
  };

  const createComponent = (props = {}) => {
    store = new Vuex.Store({
      state: {
        formErrors: Object.values(VALIDATION_FIELD_KEYS).reduce(
          (acc, cur) => ({ ...acc, [cur]: '' }),
          {},
        ),
      },
      actions: {
        setError({ state }, { key, error }) {
          state.formErrors[key] = error;
        },
      },
    });

    wrapper = mount(GeoSiteFormCore, {
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findGeoSiteFormNameField = () => wrapper.find('#site-name-field');
  const findGeoSiteFormUrlField = () => wrapper.find('#site-url-field');
  const findGeoSiteInternalUrlField = () => wrapper.find('#site-internal-url-field');
  const findErrorMessage = () => wrapper.find('.invalid-feedback');

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders Geo Site Form Name Field', () => {
      expect(findGeoSiteFormNameField().exists()).toBe(true);
    });

    it('renders Geo Site Form Url Field', () => {
      expect(findGeoSiteFormUrlField().exists()).toBe(true);
    });

    describe.each`
      primarySite
      ${true}
      ${false}
    `('internal URL', ({ primarySite }) => {
      describe(`when site is ${primarySite ? 'primary' : 'secondary'}`, () => {
        beforeEach(() => {
          createComponent({
            siteData: { ...defaultProps.siteData, primary: primarySite },
          });
        });

        it('shows the Internal URL Field', () => {
          expect(findGeoSiteInternalUrlField().exists()).toBe(true);
        });
      });
    });

    describe('errors', () => {
      describe.each`
        data               | showError | errorMessage
        ${null}            | ${true}   | ${"Site name can't be blank"}
        ${''}              | ${true}   | ${"Site name can't be blank"}
        ${STRING_OVER_255} | ${true}   | ${'Site name should be between 1 and 255 characters'}
        ${'Test'}          | ${false}  | ${null}
      `(`Name Field`, ({ data, showError, errorMessage }) => {
        beforeEach(() => {
          createComponent();
          findGeoSiteFormNameField().setValue(data);
        });

        it(`${showError ? 'shows' : 'hides'} error when data is ${data}`, () => {
          expect(findGeoSiteFormNameField().classes('is-invalid')).toBe(showError);
          if (showError) {
            expect(findErrorMessage().text()).toBe(errorMessage);
          }
        });
      });
    });

    describe.each`
      data                    | showError | errorMessage
      ${null}                 | ${true}   | ${"URL can't be blank"}
      ${''}                   | ${true}   | ${"URL can't be blank"}
      ${'abcd'}               | ${true}   | ${'URL must be a valid url (ex: https://gitlab.com)'}
      ${'https://gitlab.com'} | ${false}  | ${null}
    `(`URL Field`, ({ data, showError, errorMessage }) => {
      beforeEach(() => {
        createComponent();
        findGeoSiteFormUrlField().setValue(data);
      });

      it(`${showError ? 'shows' : 'hides'} error when data is ${data}`, () => {
        expect(findGeoSiteFormUrlField().classes('is-invalid')).toBe(showError);
        if (showError) {
          expect(findErrorMessage().text()).toBe(errorMessage);
        }
      });
    });
  });
});
