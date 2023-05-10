import { GlAlert, GlFormCheckbox, GlFormGroup } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import IterationCadenceForm from 'ee/iterations/components/iteration_cadence_form.vue';
import createCadence from 'ee/iterations/queries/cadence_create.mutation.graphql';
import updateCadence from 'ee/iterations/queries/cadence_update.mutation.graphql';
import getCadence from 'ee/iterations/queries/iteration_cadence.query.graphql';
import iterationsInCadence from 'ee/iterations/queries/group_iterations_in_cadence.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { TEST_HOST } from 'helpers/test_constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mockIterationNode, automaticIterationCadence, manualIterationCadence } from '../mock_data';

const push = jest.fn();
const $router = {
  currentRoute: {
    params: {},
  },
  push,
};

function createMockApolloProvider(requestHandlers) {
  Vue.use(VueApollo);

  return createMockApollo(requestHandlers);
}

describe('Iteration cadence form', () => {
  let wrapper;
  const groupPath = 'gitlab-org';
  const mockGroupId = 'gid://gitlab/Group/114';
  const id = 72;
  const iterationCadence = automaticIterationCadence;

  const createMutationSuccess = {
    data: { result: { iterationCadence, errors: [] } },
  };
  const createMutationFailure = {
    data: {
      result: { iterationCadence, errors: ['alas, your data is unchanged'] },
    },
  };

  const cadencesResponseMockFactory = (cadence) => {
    return jest.fn().mockResolvedValue({
      data: {
        group: {
          id: mockGroupId,
          iterationCadences: {
            nodes: [cadence],
          },
          __typename: 'Group',
        },
      },
    });
  };

  const iterationsResponseMockFactory = (iteration = mockIterationNode) => {
    return jest.fn().mockResolvedValue({
      data: {
        workspace: {
          id: mockGroupId,
          iterations: {
            nodes: [iteration],
            pageInfo: {
              hasNextPage: true,
              hasPreviousPage: true,
              startCursor: 'first-item',
              endCursor: 'last-item',
              __typename: 'PageInfo',
            },
            __typename: 'IterationConnection',
          },
          __typename: 'Group',
        },
      },
    });
  };

  function createComponent({
    cadenceHandler = cadencesResponseMockFactory(automaticIterationCadence),
    iterationsHandler = iterationsResponseMockFactory(),
    mutation = createCadence,
    mutationMock,
  } = {}) {
    const apolloProvider = createMockApolloProvider([
      [getCadence, cadenceHandler],
      [iterationsInCadence, iterationsHandler],
      [mutation, mutationMock],
    ]);

    wrapper = extendedWrapper(
      mount(IterationCadenceForm, {
        apolloProvider,
        mocks: {
          $router,
        },
        provide: {
          fullPath: groupPath,
          cadencesListPath: TEST_HOST,
          instanceTimezone: { name: 'UTC', offset: 0 },
        },
      }),
    );
  }

  const findTitleGroup = () => wrapper.findAllComponents(GlFormGroup).at(0);
  const findStartDateGroup = () => wrapper.findAllComponents(GlFormGroup).at(2);
  const findDurationGroup = () => wrapper.findAllComponents(GlFormGroup).at(3);
  const findUpcomingIterationsGroup = () => wrapper.findAllComponents(GlFormGroup).at(4);
  const findRollOverGroup = () => wrapper.findAllComponents(GlFormGroup).at(5);
  const findAutomaticSchedulingCheckbox = () => wrapper.findComponent(GlFormCheckbox);

  const findError = () => wrapper.findComponent(GlAlert);

  const findTitle = () => wrapper.find('#cadence-title');
  const findStartDate = () => wrapper.find('#cadence-start-date');
  const findUpcomingIterations = () => wrapper.find('#cadence-schedule-upcoming-iterations');
  const findDuration = () => wrapper.find('#cadence-duration');
  const findRollOver = () => wrapper.find('#cadence-rollover-issues');
  const findDescription = () => wrapper.find('#cadence-description');

  const setTitle = (value) => findTitle().vm.$emit('input', value);
  const setStartDate = (value) => findStartDate().vm.$emit('input', value);
  const setUpcomingIterations = (value) => findUpcomingIterations().vm.$emit('input', value);
  const setDuration = (value) => findDuration().vm.$emit('input', value);

  const setRollOver = (value) => {
    const checkbox = findRollOverGroup().findComponent(GlFormCheckbox).vm;
    checkbox.$emit('input', value);
    checkbox.$emit('change', value);
  };

  const setAutomaticValue = (value) => {
    const checkbox = findAutomaticSchedulingCheckbox().findComponent(GlFormCheckbox).vm;
    checkbox.$emit('input', value);
    checkbox.$emit('change', value);
  };

  const findAllFields = () => [
    findTitle(),
    findStartDate(),
    findUpcomingIterations(),
    findDuration(),
  ];

  const findSaveButton = () => wrapper.findByTestId('save-cadence');
  const findCancelButton = () => wrapper.findByTestId('cancel-create-cadence');
  const clickSave = () => findSaveButton().vm.$emit('click');
  const clickCancel = () => findCancelButton().vm.$emit('click');

  describe('Create cadence', () => {
    let mutationMock;

    beforeEach(() => {
      mutationMock = jest.fn().mockResolvedValue(createMutationSuccess);
      createComponent({ mutationMock });
    });

    it('cancel button links to list page', () => {
      clickCancel();

      expect(push).toHaveBeenCalledWith({ name: 'index' });
    });

    it('does not disable the start date field', () => {
      expect(findStartDate().attributes('disabled')).toBe(undefined);
    });

    it('does not show the description text for automation start date', () => {
      expect(findStartDateGroup().text()).not.toContain('Iterations are scheduled to start on');
    });

    it('displays the rollover message with instance timezone information', () => {
      expect(findRollOverGroup().text()).toContain(
        'Incomplete issues will be added to the next iteration at midnight, [UTC 0] UTC.',
      );
    });

    describe('when a new automation start date is selected', () => {
      it('shows the description text with the correct weekday for automation start date', async () => {
        setStartDate('2022-07-13');

        await nextTick();

        expect(findStartDateGroup().text()).toContain(
          'Iterations are scheduled to start on Wednesdays.',
        );
      });
    });

    describe('save', () => {
      const title = 'Iteration 5';
      const startDate = '2020-05-05';
      const durationInWeeks = 2;
      const rollOver = true;
      const iterationsInAdvance = 6;

      it('triggers mutation with form data', async () => {
        setTitle(title);
        setStartDate(startDate);
        setDuration(durationInWeeks);
        setRollOver(rollOver);
        setUpcomingIterations(iterationsInAdvance);

        clickSave();

        await nextTick();

        expect(findError().exists()).toBe(false);
        expect(mutationMock).toHaveBeenCalledWith({
          input: {
            groupPath,
            title,
            automatic: true,
            startDate,
            durationInWeeks,
            rollOver,
            iterationsInAdvance,
            active: true,
            description: '',
          },
        });
      });

      it('displays mutation errors on failure', async () => {
        mutationMock = jest.fn().mockResolvedValue(createMutationFailure);
        createComponent({ mutationMock });

        setTitle(title);
        setStartDate(startDate);
        setDuration(durationInWeeks);
        setRollOver(rollOver);
        setUpcomingIterations(iterationsInAdvance);

        clickSave();

        await waitForPromises();

        expect(findError().exists()).toBe(true);
        expect(findError().text()).toContain('alas, your data is unchanged');
      });

      it('redirects to Iteration page on success', async () => {
        setTitle(title);
        setStartDate(startDate);
        setDuration(durationInWeeks);
        setUpcomingIterations(iterationsInAdvance);

        clickSave();

        await waitForPromises();

        expect(push).toHaveBeenCalledWith({
          name: 'index',
          query: {
            createdCadenceId: id,
          },
        });
      });

      it('does not submit if required fields missing', () => {
        clickSave();

        expect(mutationMock).not.toHaveBeenCalled();
        expect(findTitleGroup().text()).toContain('This field is required');
        expect(findStartDateGroup().text()).toContain('This field is required');
        expect(findDurationGroup().text()).toContain('This field is required');
        expect(findUpcomingIterationsGroup().text()).toContain('This field is required');
      });

      it('loading=false on error', async () => {
        mutationMock = jest.fn().mockResolvedValue(createMutationFailure);
        createComponent({ mutationMock });

        clickSave();

        await waitForPromises();

        expect(findSaveButton().props('loading')).toBe(false);
      });
    });

    describe('automated scheduling disabled', () => {
      beforeEach(() => {
        setAutomaticValue(false);
      });

      it('disables the fields concerning automatic scheduling', () => {
        expect(findUpcomingIterations().attributes('disabled')).toBeDefined();
        expect(findDuration().attributes('disabled')).toBeDefined();
        expect(findStartDate().attributes('disabled')).toBeDefined();
      });

      it('resets the fields concerning automatic scheduling on disabling automatic scheduling', async () => {
        const title = 'Iteration 5';

        setUpcomingIterations(10);
        setDuration(2);

        setAutomaticValue(false);

        await nextTick();

        setTitle(title);

        clickSave();

        await nextTick();

        expect(mutationMock).toHaveBeenCalledWith({
          input: {
            groupPath,
            title,
            automatic: false,
            startDate: null,
            rollOver: false,
            durationInWeeks: null,
            iterationsInAdvance: null,
            description: '',
            active: true,
          },
        });
      });
    });
  });

  describe('Edit cadence', () => {
    const cadenceHandler = cadencesResponseMockFactory(automaticIterationCadence);

    const mutationMock = jest.fn().mockResolvedValue(createMutationSuccess);

    beforeEach(() => {
      $router.currentRoute.params.cadenceId = id;

      createComponent({ cadenceHandler, mutation: updateCadence, mutationMock });
    });

    afterEach(() => {
      delete $router.currentRoute.params.cadenceId;
    });

    it('shows correct title and button text', () => {
      expect(wrapper.text()).toContain(wrapper.vm.i18n.edit.title);
      expect(wrapper.text()).toContain(wrapper.vm.i18n.edit.save);
    });

    it('triggers read query with correct variables', () => {
      expect(cadenceHandler).toHaveBeenCalledWith({
        fullPath: groupPath,
        id: automaticIterationCadence.id,
      });
    });

    it('disables fields while loading', async () => {
      createComponent();

      findAllFields().forEach(({ element }) => {
        expect(element).toBeDisabled();
      });

      await waitForPromises();

      findAllFields().forEach(({ element }) => {
        expect(element).not.toBeDisabled();
      });
    });

    it('does not disable the start date field when the first iteration is upcoming', async () => {
      await waitForPromises();

      expect(findStartDate().attributes('disabled')).toBe(undefined);
    });

    it('shows the description text with the correct weekday for automation start date', async () => {
      await waitForPromises();

      expect(findStartDateGroup().text()).toContain('Iterations are scheduled to start on Sundays');
    });

    it('displays query errors on failure', async () => {
      createComponent({
        iterationsHandler: jest.fn().mockRejectedValue(new Error('GraphQL error')),
      });

      await waitForPromises();

      expect(findError().exists()).toBe(true);
      expect(findError().text()).toContain('Error: GraphQL error');
    });

    describe('when a cadence is manually managed', () => {
      beforeEach(async () => {
        createComponent({
          cadenceHandler: cadencesResponseMockFactory(manualIterationCadence),
        });

        await waitForPromises();

        await nextTick();
      });

      it('highlights fields required for automatic scheduling', () => {
        expect(findStartDateGroup().text()).toContain('This field is required');
        expect(findDurationGroup().text()).toContain('This field is required');
        expect(findUpcomingIterationsGroup().text()).toContain('This field is required');
      });
    });

    it('fills fields with existing cadence info after loading', async () => {
      createComponent({ mutation: updateCadence });

      await waitForPromises();

      await nextTick();

      expect(findTitle().element.value).toBe(iterationCadence.title);
      expect(findStartDate().element.value).toBe(iterationCadence.startDate);
      expect(findUpcomingIterations().element.value).toBe(
        `${iterationCadence.iterationsInAdvance}`,
      );
      expect(findDuration().element.value).toBe(`${iterationCadence.durationInWeeks}`);
      expect(findRollOver().element.checked).toBe(iterationCadence.rollOver);
      expect(findDescription().element.value).toBe(iterationCadence.description);
    });

    it('updates roll over issues checkbox', async () => {
      await waitForPromises();
      const rollOver = true;
      setRollOver(rollOver);

      const { __typename, ...cadenceWithoutTypename } = iterationCadence;

      clickSave();

      await waitForPromises();

      expect(findError().exists()).toBe(false);
      expect(mutationMock).toHaveBeenCalledWith({
        input: {
          ...cadenceWithoutTypename,
          rollOver,
        },
      });
    });
  });
});
