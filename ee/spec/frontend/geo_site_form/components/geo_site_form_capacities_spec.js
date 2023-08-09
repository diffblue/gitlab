import { GlLink } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import GeoSiteFormCapacities from 'ee/geo_site_form/components/geo_site_form_capacities.vue';
import {
  VALIDATION_FIELD_KEYS,
  REVERIFICATION_MORE_INFO,
  BACKFILL_MORE_INFO,
} from 'ee/geo_site_form/constants';
import { MOCK_SITE } from '../mock_data';

Vue.use(Vuex);

describe('GeoSiteFormCapacities', () => {
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

    wrapper = mount(GeoSiteFormCapacities, {
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findGeoSiteFormCapacitiesSectionDescription = () => wrapper.find('p');
  const findGeoSiteFormCapacitiesMoreInfoLink = () => wrapper.findComponent(GlLink);
  const findGeoSiteFormRepositoryCapacityField = () =>
    wrapper.find('#site-repository-capacity-field');
  const findGeoSiteFormFileCapacityField = () => wrapper.find('#site-file-capacity-field');
  const findGeoSiteFormContainerRepositoryCapacityField = () =>
    wrapper.find('#site-container-repository-capacity-field');
  const findGeoSiteFormVerificationCapacityField = () =>
    wrapper.find('#site-verification-capacity-field');
  const findGeoSiteFormReverificationIntervalField = () =>
    wrapper.find('#site-reverification-interval-field');
  const findErrorMessage = () => wrapper.find('.invalid-feedback');
  const findFieldLabel = (id) => wrapper.vm.formGroups.find((el) => el.id === id).label;

  describe('template', () => {
    describe.each`
      primarySite | description                                                                                   | link
      ${true}     | ${'Set verification limit and frequency.'}                                                    | ${REVERIFICATION_MORE_INFO}
      ${false}    | ${'Limit the number of concurrent operations this secondary site can run in the background.'} | ${BACKFILL_MORE_INFO}
    `(`section description`, ({ primarySite, description, link }) => {
      describe(`when site is ${primarySite ? 'primary' : 'secondary'}`, () => {
        beforeEach(() => {
          createComponent({
            siteData: { ...defaultProps.siteData, primary: primarySite },
          });
        });

        it(`sets section description correctly`, () => {
          expect(findGeoSiteFormCapacitiesSectionDescription().text()).toContain(description);
        });

        it(`sets section More Information link correctly`, () => {
          expect(findGeoSiteFormCapacitiesMoreInfoLink().attributes('href')).toBe(link);
        });
      });
    });

    describe.each`
      primarySite | showRepoCapacity | showFileCapacity | showVerificationCapacity | showContainerCapacity | showReverificationInterval
      ${true}     | ${false}         | ${false}         | ${true}                  | ${false}              | ${true}
      ${false}    | ${true}          | ${true}          | ${true}                  | ${true}               | ${false}
    `(
      `conditional fields`,
      ({
        primarySite,
        showRepoCapacity,
        showFileCapacity,
        showContainerCapacity,
        showVerificationCapacity,
        showReverificationInterval,
      }) => {
        describe(`when site is ${primarySite ? 'primary' : 'secondary'}`, () => {
          beforeEach(() => {
            createComponent({
              siteData: { ...defaultProps.siteData, primary: primarySite },
            });
          });

          it(`it ${showRepoCapacity ? 'shows' : 'hides'} the Repository Capacity Field`, () => {
            expect(findGeoSiteFormRepositoryCapacityField().exists()).toBe(showRepoCapacity);
          });

          it(`it ${showFileCapacity ? 'shows' : 'hides'} the File Capacity Field`, () => {
            expect(findGeoSiteFormFileCapacityField().exists()).toBe(showFileCapacity);
          });

          it(`it ${
            showContainerCapacity ? 'shows' : 'hides'
          } the Container Repository Capacity Field`, () => {
            expect(findGeoSiteFormContainerRepositoryCapacityField().exists()).toBe(
              showContainerCapacity,
            );
          });

          it(`it ${
            showVerificationCapacity ? 'shows' : 'hides'
          } the Verification Capacity Field`, () => {
            expect(findGeoSiteFormVerificationCapacityField().exists()).toBe(
              showVerificationCapacity,
            );
          });

          it(`it ${
            showReverificationInterval ? 'shows' : 'hides'
          } the Reverification Interval Field`, () => {
            expect(findGeoSiteFormReverificationIntervalField().exists()).toBe(
              showReverificationInterval,
            );
          });
        });
      },
    );

    describe.each`
      data    | showError | errorMessage
      ${null} | ${true}   | ${"can't be blank"}
      ${''}   | ${true}   | ${"can't be blank"}
      ${-1}   | ${true}   | ${'should be between 1-999'}
      ${0}    | ${true}   | ${'should be between 1-999'}
      ${1}    | ${false}  | ${null}
      ${999}  | ${false}  | ${null}
      ${1000} | ${true}   | ${'should be between 1-999'}
    `(`errors`, ({ data, showError, errorMessage }) => {
      describe('when site is primary', () => {
        beforeEach(() => {
          createComponent({
            siteData: { ...defaultProps.siteData, primary: true },
          });
        });

        describe('Verification Capacity Field', () => {
          beforeEach(() => {
            findGeoSiteFormVerificationCapacityField().setValue(data);
          });

          it(`${showError ? 'shows' : 'hides'} error when data is ${data}`, () => {
            expect(findGeoSiteFormVerificationCapacityField().classes('is-invalid')).toBe(
              showError,
            );
            if (showError) {
              expect(findErrorMessage().text()).toBe(
                `${findFieldLabel('site-verification-capacity-field')} ${errorMessage}`,
              );
            }
          });
        });

        describe('Reverification Interval Field', () => {
          beforeEach(() => {
            findGeoSiteFormReverificationIntervalField().setValue(data);
          });

          it(`${showError ? 'shows' : 'hides'} error when data is ${data}`, () => {
            expect(findGeoSiteFormReverificationIntervalField().classes('is-invalid')).toBe(
              showError,
            );
            if (showError) {
              expect(findErrorMessage().text()).toBe(
                `${findFieldLabel('site-reverification-interval-field')} ${errorMessage}`,
              );
            }
          });
        });
      });

      describe('when site is secondary', () => {
        beforeEach(() => {
          createComponent();
        });

        describe('Repository Capacity Field', () => {
          beforeEach(() => {
            findGeoSiteFormRepositoryCapacityField().setValue(data);
          });

          it(`${showError ? 'shows' : 'hides'} error when data is ${data}`, () => {
            expect(findGeoSiteFormRepositoryCapacityField().classes('is-invalid')).toBe(showError);
            if (showError) {
              expect(findErrorMessage().text()).toBe(
                `${findFieldLabel('site-repository-capacity-field')} ${errorMessage}`,
              );
            }
          });
        });

        describe('File Capacity Field', () => {
          beforeEach(() => {
            findGeoSiteFormFileCapacityField().setValue(data);
          });

          it(`${showError ? 'shows' : 'hides'} error when data is ${data}`, () => {
            expect(findGeoSiteFormFileCapacityField().classes('is-invalid')).toBe(showError);
            if (showError) {
              expect(findErrorMessage().text()).toBe(
                `${findFieldLabel('site-file-capacity-field')} ${errorMessage}`,
              );
            }
          });
        });

        describe('Container Repository Capacity Field', () => {
          beforeEach(() => {
            findGeoSiteFormContainerRepositoryCapacityField().setValue(data);
          });

          it(`${showError ? 'shows' : 'hides'} error when data is ${data}`, () => {
            expect(findGeoSiteFormContainerRepositoryCapacityField().classes('is-invalid')).toBe(
              showError,
            );
            if (showError) {
              expect(findErrorMessage().text()).toBe(
                `${findFieldLabel('site-container-repository-capacity-field')} ${errorMessage}`,
              );
            }
          });
        });

        describe('Verification Capacity Field', () => {
          beforeEach(() => {
            findGeoSiteFormVerificationCapacityField().setValue(data);
          });

          it(`${showError ? 'shows' : 'hides'} error when data is ${data}`, () => {
            expect(findGeoSiteFormVerificationCapacityField().classes('is-invalid')).toBe(
              showError,
            );
            if (showError) {
              expect(findErrorMessage().text()).toBe(
                `${findFieldLabel('site-verification-capacity-field')} ${errorMessage}`,
              );
            }
          });
        });
      });
    });
  });

  describe('computed', () => {
    describe('visibleFormGroups', () => {
      describe('when site is primary', () => {
        beforeEach(() => {
          createComponent({
            siteData: { ...defaultProps.siteData, primary: true },
          });
        });

        it('contains conditional form groups for primary', () => {
          expect(wrapper.vm.visibleFormGroups.some((g) => g.conditional === 'primary')).toBe(true);
        });

        it('does not contain conditional form groups for secondary', () => {
          expect(wrapper.vm.visibleFormGroups.some((g) => g.conditional === 'secondary')).toBe(
            false,
          );
        });
      });

      describe('when site is secondary', () => {
        beforeEach(() => {
          createComponent();
        });

        it('contains conditional form groups for secondary', () => {
          expect(wrapper.vm.visibleFormGroups.some((g) => g.conditional === 'secondary')).toBe(
            true,
          );
        });

        it('does not contain conditional form groups for primary', () => {
          expect(wrapper.vm.visibleFormGroups.some((g) => g.conditional === 'primary')).toBe(false);
        });
      });
    });
  });
});
