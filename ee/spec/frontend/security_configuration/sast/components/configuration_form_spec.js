import * as Sentry from '@sentry/browser';
import { shallowMount } from '@vue/test-utils';
import { merge } from 'lodash';
import DynamicFields from 'ee/security_configuration/components/dynamic_fields.vue';
import ConfigurationForm from 'ee/security_configuration/sast/components/configuration_form.vue';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import configureSastMutation from '~/security_configuration/graphql/configure_sast.mutation.graphql';
import { makeEntities, makeSastCiConfiguration } from '../../helpers';

jest.mock('~/lib/utils/url_utility');

const projectPath = 'group/project';
const securityConfigurationPath = '/security/configuration';
const newMergeRequestPath = '/merge_request/new';

describe('ConfigurationForm component', () => {
  let wrapper;
  let sastCiConfiguration;

  let pendingPromiseResolvers;
  const fulfillPendingPromises = () => {
    pendingPromiseResolvers.forEach((resolve) => resolve());
  };

  const createComponent = ({ mutationResult, ...options } = {}) => {
    sastCiConfiguration = makeSastCiConfiguration();

    wrapper = shallowMount(
      ConfigurationForm,
      merge(
        {
          provide: {
            projectPath,
            securityConfigurationPath,
          },
          propsData: {
            sastCiConfiguration,
          },
          mocks: {
            $apollo: {
              mutate: jest.fn(
                () =>
                  new Promise((resolve) => {
                    pendingPromiseResolvers.push(() =>
                      resolve({
                        data: { configureSast: mutationResult },
                      }),
                    );
                  }),
              ),
            },
          },
        },
        options,
      ),
    );
  };

  const findForm = () => wrapper.find('form');
  const findSubmitButton = () => wrapper.findComponent({ ref: 'submitButton' });
  const findErrorAlert = () => wrapper.find('[data-testid="analyzers-error-alert"]');
  const findCancelButton = () => wrapper.findComponent({ ref: 'cancelButton' });
  const findDynamicFieldsComponents = () => wrapper.findAllComponents(DynamicFields);

  const expectPayloadForEntities = () => {
    const expectedPayload = {
      mutation: configureSastMutation,
      variables: {
        input: {
          projectPath,
          configuration: {
            global: [
              {
                field: 'field0',
                defaultValue: 'defaultValue0',
                value: 'value0',
              },
            ],
            pipeline: [
              {
                field: 'field1',
                defaultValue: 'defaultValue1',
                value: 'value1',
              },
            ],
          },
        },
      },
    };

    expect(wrapper.vm.$apollo.mutate.mock.calls).toEqual([[expectedPayload]]);
  };

  beforeEach(() => {
    pendingPromiseResolvers = [];
  });

  describe.each`
    type          | expectedPosition
    ${'global'}   | ${0}
    ${'pipeline'} | ${1}
  `('the $type DynamicFields component', ({ type, expectedPosition }) => {
    let dynamicFields;

    beforeEach(() => {
      createComponent();
      dynamicFields = findDynamicFieldsComponents().at(expectedPosition);
    });

    it('renders', () => {
      expect(dynamicFields.exists()).toBe(true);
    });

    it(`receives a copy of the ${type} entities`, () => {
      const entitiesProp = dynamicFields.props('entities');

      expect(entitiesProp).not.toBe(sastCiConfiguration[type].nodes);
      expect(entitiesProp).toEqual(sastCiConfiguration[type].nodes);
    });

    describe('when it emits an input event', () => {
      let newEntities;

      beforeEach(() => {
        newEntities = makeEntities(1);
        dynamicFields.vm.$emit(DynamicFields.model.event, newEntities);
      });

      it('updates the entities binding', () => {
        expect(dynamicFields.props('entities')).toBe(newEntities);
      });
    });
  });

  describe('when submitting the form', () => {
    beforeEach(() => {
      jest.spyOn(Sentry, 'captureException').mockImplementation();
    });

    describe.each`
      context             | successPath | errors
      ${'no successPath'} | ${''}       | ${[]}
      ${'any errors'}     | ${''}       | ${['an error']}
    `('given an unsuccessful endpoint response due to $context', ({ successPath, errors }) => {
      beforeEach(() => {
        createComponent({
          mutationResult: {
            successPath,
            errors,
          },
        });

        findForm().trigger('submit');
      });

      it('includes the value of each entity in the payload', () => {
        expectPayloadForEntities();
      });

      it(`sets the submit button's loading prop to true`, () => {
        expect(findSubmitButton().props('loading')).toBe(true);
      });

      describe('after async tasks', () => {
        beforeEach(fulfillPendingPromises);

        it('does not call redirectTo', () => {
          expect(redirectTo).not.toHaveBeenCalled(); // eslint-disable-line import/no-deprecated
        });

        it('displays an alert message', () => {
          expect(findErrorAlert().exists()).toBe(true);
        });

        it('sends the error to Sentry', () => {
          expect(Sentry.captureException.mock.calls).toMatchObject([
            [{ message: expect.stringMatching(/merge request.*fail/) }],
          ]);
        });

        it(`sets the submit button's loading prop to false`, () => {
          expect(findSubmitButton().props('loading')).toBe(false);
        });

        describe('submitting again after a previous error', () => {
          beforeEach(() => {
            findForm().trigger('submit');
          });

          it('hides the alert message', () => {
            expect(findErrorAlert().exists()).toBe(false);
          });
        });
      });
    });

    describe('given a successful endpoint response', () => {
      beforeEach(() => {
        createComponent({
          mutationResult: {
            successPath: newMergeRequestPath,
            errors: [],
          },
        });

        findForm().trigger('submit');
      });

      it('includes the value of each entity in the payload', () => {
        expectPayloadForEntities();
      });

      it(`sets the submit button's loading prop to true`, () => {
        expect(findSubmitButton().props().loading).toBe(true);
      });

      describe('after async tasks', () => {
        beforeEach(fulfillPendingPromises);

        it('calls redirectTo', () => {
          expect(redirectTo).toHaveBeenCalledWith(newMergeRequestPath); // eslint-disable-line import/no-deprecated
        });

        it('does not display an alert message', () => {
          expect(findErrorAlert().exists()).toBe(false);
        });

        it('does not call Sentry.captureException', () => {
          expect(Sentry.captureException).not.toHaveBeenCalled();
        });

        it('keeps the loading prop set to true', () => {
          // This is done for UX reasons. If the loading prop is set to false
          // on success, then there's a period where the button is clickable
          // again. Instead, we want the button to display a loading indicator
          // for the remainder of the lifetime of the page (i.e., until the
          // browser can start painting the new page it's been redirected to).
          expect(findSubmitButton().props().loading).toBe(true);
        });
      });
    });
  });

  describe('the cancel button', () => {
    beforeEach(() => {
      createComponent();
    });

    it('exists', () => {
      expect(findCancelButton().exists()).toBe(true);
    });

    it('links to the Security Configuration page', () => {
      expect(findCancelButton().attributes('href')).toBe(securityConfigurationPath);
    });
  });
});
