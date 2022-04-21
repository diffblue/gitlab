import { GlAlert, GlFormCheckbox, GlFormGroup } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import IterationCadenceForm from 'ee/iterations/components/iteration_cadence_form.vue';
import createCadence from 'ee/iterations/queries/cadence_create.mutation.graphql';
import updateCadence from 'ee/iterations/queries/cadence_update.mutation.graphql';
import getCadence from 'ee/iterations/queries/iteration_cadence.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { TEST_HOST } from 'helpers/test_constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { automaticIterationCadence, manualIterationCadence } from '../mock_data';

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
  const getCadenceSuccess = {
    data: {
      group: {
        id: 'gid://gitlab/Group/114',
        iterationCadences: {
          nodes: [automaticIterationCadence],
        },
      },
    },
  };

  function createComponent({
    query = getCadence,
    resolverMock,
    mutation = createCadence,
    mutationMock,
  } = {}) {
    const apolloProvider = createMockApolloProvider([
      [query, resolverMock],
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
        },
      }),
    );
  }

  afterEach(() => {
    wrapper.destroy();
  });

  const findTitleGroup = () => wrapper.findAllComponents(GlFormGroup).at(0);
  const findStartDateGroup = () => wrapper.findAllComponents(GlFormGroup).at(1);
  const findDurationGroup = () => wrapper.findAllComponents(GlFormGroup).at(2);
  const findFutureIterationsGroup = () => wrapper.findAllComponents(GlFormGroup).at(3);
  const findRollOverGroup = () => wrapper.findAllComponents(GlFormGroup).at(4);

  const findError = () => wrapper.findComponent(GlAlert);

  const findTitle = () => wrapper.find('#cadence-title');
  const findStartDate = () => wrapper.find('#cadence-start-date');
  const findFutureIterations = () => wrapper.find('#cadence-schedule-future-iterations');
  const findDuration = () => wrapper.find('#cadence-duration');
  const findRollOver = () => wrapper.find('#cadence-rollover-issues');
  const findDescription = () => wrapper.find('#cadence-description');

  const setTitle = (value) => findTitle().vm.$emit('input', value);
  const setStartDate = (value) => findStartDate().vm.$emit('input', value);
  const setFutureIterations = (value) => findFutureIterations().vm.$emit('input', value);
  const setDuration = (value) => findDuration().vm.$emit('input', value);

  const setRollOver = (value) => {
    const checkbox = findRollOverGroup().findComponent(GlFormCheckbox).vm;
    checkbox.$emit('input', value);
    checkbox.$emit('change', value);
  };

  const findAllFields = () => [
    findTitle(),
    findStartDate(),
    findFutureIterations(),
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
        setFutureIterations(iterationsInAdvance);

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
        setFutureIterations(iterationsInAdvance);

        clickSave();

        await waitForPromises();

        expect(findError().exists()).toBe(true);
        expect(findError().text()).toContain('alas, your data is unchanged');
      });

      it('redirects to Iteration page on success', async () => {
        setTitle(title);
        setStartDate(startDate);
        setDuration(durationInWeeks);
        setFutureIterations(iterationsInAdvance);

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
        expect(findFutureIterationsGroup().text()).toContain('This field is required');
      });

      it('loading=false on error', async () => {
        mutationMock = jest.fn().mockResolvedValue(createMutationFailure);
        createComponent({ mutationMock });

        clickSave();

        await waitForPromises();

        expect(findSaveButton().props('loading')).toBe(false);
      });
    });
  });

  describe('Edit cadence', () => {
    const query = getCadence;
    const resolverMock = jest.fn().mockResolvedValue(getCadenceSuccess);
    const mutationMock = jest.fn().mockResolvedValue(createMutationSuccess);

    beforeEach(() => {
      $router.currentRoute.params.cadenceId = id;

      createComponent({ query, resolverMock, mutation: updateCadence, mutationMock });
    });

    afterEach(() => {
      delete $router.currentRoute.params.cadenceId;
    });

    it('shows correct title and button text', () => {
      expect(wrapper.text()).toContain(wrapper.vm.i18n.edit.title);
      expect(wrapper.text()).toContain(wrapper.vm.i18n.edit.save);
    });

    it('triggers read query with correct variables', () => {
      expect(resolverMock).toHaveBeenCalledWith({
        fullPath: groupPath,
        id: automaticIterationCadence.id,
      });
    });

    it('disables fields while loading', async () => {
      createComponent({ query, resolverMock });

      findAllFields().forEach(({ element }) => {
        expect(element).toBeDisabled();
      });

      await waitForPromises();

      findAllFields().forEach(({ element }) => {
        expect(element).not.toBeDisabled();
      });
    });

    it('does not show the deprecation alert for automatic cadence', async () => {
      createComponent({ query, resolverMock });

      await waitForPromises();

      expect(wrapper.text()).not.toContain('This cadence requires an update');
    });

    describe('when a cadence is manually managed', () => {
      beforeEach(async () => {
        createComponent({
          query,
          resolverMock: jest.fn().mockResolvedValue({
            data: {
              group: {
                id: 'gid://gitlab/Group/114',
                iterationCadences: {
                  nodes: [manualIterationCadence],
                },
              },
            },
          }),
        });

        await waitForPromises();

        await nextTick();
      });

      it('displays the deprecation message', async () => {
        expect(wrapper.text()).toContain('This cadence requires an update');
      });

      it('highlights fields required for automatic scheduling', async () => {
        expect(findStartDateGroup().text()).toContain('This field is required');
        expect(findDurationGroup().text()).toContain('This field is required');
        expect(findFutureIterationsGroup().text()).toContain('This field is required');
      });
    });

    it('fills fields with existing cadence info after loading', async () => {
      createComponent({ query, resolverMock, mutation: updateCadence });

      await waitForPromises();

      await nextTick();

      expect(findTitle().element.value).toBe(iterationCadence.title);
      expect(findStartDate().element.value).toBe(iterationCadence.startDate);
      expect(findFutureIterations().element.value).toBe(`${iterationCadence.iterationsInAdvance}`);
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
