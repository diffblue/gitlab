import { GlLink } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import GeoNodeFormCapacities from 'ee/geo_node_form/components/geo_node_form_capacities.vue';
import {
  VALIDATION_FIELD_KEYS,
  REVERIFICATION_MORE_INFO,
  BACKFILL_MORE_INFO,
} from 'ee/geo_node_form/constants';
import { MOCK_NODE } from '../mock_data';

Vue.use(Vuex);

describe('GeoNodeFormCapacities', () => {
  let wrapper;
  let store;

  const defaultProps = {
    nodeData: MOCK_NODE,
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

    wrapper = mount(GeoNodeFormCapacities, {
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

  const findGeoNodeFormCapcitiesSectionDescription = () => wrapper.find('p');
  const findGeoNodeFormCapacitiesMoreInfoLink = () => wrapper.find(GlLink);
  const findGeoNodeFormRepositoryCapacityField = () =>
    wrapper.find('#node-repository-capacity-field');
  const findGeoNodeFormFileCapacityField = () => wrapper.find('#node-file-capacity-field');
  const findGeoNodeFormContainerRepositoryCapacityField = () =>
    wrapper.find('#node-container-repository-capacity-field');
  const findGeoNodeFormVerificationCapacityField = () =>
    wrapper.find('#node-verification-capacity-field');
  const findGeoNodeFormReverificationIntervalField = () =>
    wrapper.find('#node-reverification-interval-field');
  const findErrorMessage = () => wrapper.find('.invalid-feedback');
  const findFieldLabel = (id) => wrapper.vm.formGroups.find((el) => el.id === id).label;

  describe('template', () => {
    describe.each`
      primaryNode | description                                                                                   | link
      ${true}     | ${'Set verification limit and frequency.'}                                                    | ${REVERIFICATION_MORE_INFO}
      ${false}    | ${'Limit the number of concurrent operations this secondary site can run in the background.'} | ${BACKFILL_MORE_INFO}
    `(`section description`, ({ primaryNode, description, link }) => {
      describe(`when node is ${primaryNode ? 'primary' : 'secondary'}`, () => {
        beforeEach(() => {
          createComponent({
            nodeData: { ...defaultProps.nodeData, primary: primaryNode },
          });
        });

        it(`sets section description correctly`, () => {
          expect(findGeoNodeFormCapcitiesSectionDescription().text()).toContain(description);
        });

        it(`sets section More Information link correctly`, () => {
          expect(findGeoNodeFormCapacitiesMoreInfoLink().attributes('href')).toBe(link);
        });
      });
    });

    describe.each`
      primaryNode | showRepoCapacity | showFileCapacity | showVerificationCapacity | showContainerCapacity | showReverificationInterval
      ${true}     | ${false}         | ${false}         | ${true}                  | ${false}              | ${true}
      ${false}    | ${true}          | ${true}          | ${true}                  | ${true}               | ${false}
    `(
      `conditional fields`,
      ({
        primaryNode,
        showRepoCapacity,
        showFileCapacity,
        showContainerCapacity,
        showVerificationCapacity,
        showReverificationInterval,
      }) => {
        describe(`when node is ${primaryNode ? 'primary' : 'secondary'}`, () => {
          beforeEach(() => {
            createComponent({
              nodeData: { ...defaultProps.nodeData, primary: primaryNode },
            });
          });

          it(`it ${showRepoCapacity ? 'shows' : 'hides'} the Repository Capacity Field`, () => {
            expect(findGeoNodeFormRepositoryCapacityField().exists()).toBe(showRepoCapacity);
          });

          it(`it ${showFileCapacity ? 'shows' : 'hides'} the File Capacity Field`, () => {
            expect(findGeoNodeFormFileCapacityField().exists()).toBe(showFileCapacity);
          });

          it(`it ${
            showContainerCapacity ? 'shows' : 'hides'
          } the Container Repository Capacity Field`, () => {
            expect(findGeoNodeFormContainerRepositoryCapacityField().exists()).toBe(
              showContainerCapacity,
            );
          });

          it(`it ${
            showVerificationCapacity ? 'shows' : 'hides'
          } the Verification Capacity Field`, () => {
            expect(findGeoNodeFormVerificationCapacityField().exists()).toBe(
              showVerificationCapacity,
            );
          });

          it(`it ${
            showReverificationInterval ? 'shows' : 'hides'
          } the Reverification Interval Field`, () => {
            expect(findGeoNodeFormReverificationIntervalField().exists()).toBe(
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
      describe('when node is primary', () => {
        beforeEach(() => {
          createComponent({
            nodeData: { ...defaultProps.nodeData, primary: true },
          });
        });

        describe('Verification Capacity Field', () => {
          beforeEach(() => {
            findGeoNodeFormVerificationCapacityField().setValue(data);
          });

          it(`${showError ? 'shows' : 'hides'} error when data is ${data}`, () => {
            expect(findGeoNodeFormVerificationCapacityField().classes('is-invalid')).toBe(
              showError,
            );
            if (showError) {
              expect(findErrorMessage().text()).toBe(
                `${findFieldLabel('node-verification-capacity-field')} ${errorMessage}`,
              );
            }
          });
        });

        describe('Reverification Interval Field', () => {
          beforeEach(() => {
            findGeoNodeFormReverificationIntervalField().setValue(data);
          });

          it(`${showError ? 'shows' : 'hides'} error when data is ${data}`, () => {
            expect(findGeoNodeFormReverificationIntervalField().classes('is-invalid')).toBe(
              showError,
            );
            if (showError) {
              expect(findErrorMessage().text()).toBe(
                `${findFieldLabel('node-reverification-interval-field')} ${errorMessage}`,
              );
            }
          });
        });
      });

      describe('when node is secondary', () => {
        beforeEach(() => {
          createComponent();
        });

        describe('Repository Capacity Field', () => {
          beforeEach(() => {
            findGeoNodeFormRepositoryCapacityField().setValue(data);
          });

          it(`${showError ? 'shows' : 'hides'} error when data is ${data}`, () => {
            expect(findGeoNodeFormRepositoryCapacityField().classes('is-invalid')).toBe(showError);
            if (showError) {
              expect(findErrorMessage().text()).toBe(
                `${findFieldLabel('node-repository-capacity-field')} ${errorMessage}`,
              );
            }
          });
        });

        describe('File Capacity Field', () => {
          beforeEach(() => {
            findGeoNodeFormFileCapacityField().setValue(data);
          });

          it(`${showError ? 'shows' : 'hides'} error when data is ${data}`, () => {
            expect(findGeoNodeFormFileCapacityField().classes('is-invalid')).toBe(showError);
            if (showError) {
              expect(findErrorMessage().text()).toBe(
                `${findFieldLabel('node-file-capacity-field')} ${errorMessage}`,
              );
            }
          });
        });

        describe('Container Repository Capacity Field', () => {
          beforeEach(() => {
            findGeoNodeFormContainerRepositoryCapacityField().setValue(data);
          });

          it(`${showError ? 'shows' : 'hides'} error when data is ${data}`, () => {
            expect(findGeoNodeFormContainerRepositoryCapacityField().classes('is-invalid')).toBe(
              showError,
            );
            if (showError) {
              expect(findErrorMessage().text()).toBe(
                `${findFieldLabel('node-container-repository-capacity-field')} ${errorMessage}`,
              );
            }
          });
        });

        describe('Verification Capacity Field', () => {
          beforeEach(() => {
            findGeoNodeFormVerificationCapacityField().setValue(data);
          });

          it(`${showError ? 'shows' : 'hides'} error when data is ${data}`, () => {
            expect(findGeoNodeFormVerificationCapacityField().classes('is-invalid')).toBe(
              showError,
            );
            if (showError) {
              expect(findErrorMessage().text()).toBe(
                `${findFieldLabel('node-verification-capacity-field')} ${errorMessage}`,
              );
            }
          });
        });
      });
    });
  });

  describe('computed', () => {
    describe('visibleFormGroups', () => {
      describe('when node is primary', () => {
        beforeEach(() => {
          createComponent({
            nodeData: { ...defaultProps.nodeData, primary: true },
          });
        });

        it('contains conditional form groups for primary', () => {
          expect(
            wrapper.vm.visibleFormGroups.some((g) => g.conditional === 'primary'),
          ).toBeTruthy();
        });

        it('does not contain conditional form groups for secondary', () => {
          expect(
            wrapper.vm.visibleFormGroups.some((g) => g.conditional === 'secondary'),
          ).toBeFalsy();
        });
      });

      describe('when node is secondary', () => {
        beforeEach(() => {
          createComponent();
        });

        it('contains conditional form groups for secondary', () => {
          expect(
            wrapper.vm.visibleFormGroups.some((g) => g.conditional === 'secondary'),
          ).toBeTruthy();
        });

        it('does not contain conditional form groups for primary', () => {
          expect(wrapper.vm.visibleFormGroups.some((g) => g.conditional === 'primary')).toBeFalsy();
        });
      });
    });
  });
});
