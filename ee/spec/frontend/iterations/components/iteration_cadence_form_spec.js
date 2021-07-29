import { GlAlert, GlFormCheckbox, GlFormGroup } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import IterationCadenceForm from 'ee/iterations/components/iteration_cadence_form.vue';
import createCadence from 'ee/iterations/queries/cadence_create.mutation.graphql';
import getCadence from 'ee/iterations/queries/iteration_cadence.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { TEST_HOST } from 'helpers/test_constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

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
  const iterationCadence = {
    id: `gid://gitlab/Iterations::Cadence/${id}`,
    title: 'An iteration',
    automatic: true,
    rollOver: false,
    durationInWeeks: '3',
    description: 'The words',
    duration: '3',
    startDate: '2020-06-28',
    iterationsInAdvance: '2',
  };

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
          nodes: [iterationCadence],
        },
      },
    },
  };

  function createComponent({ query = createCadence, resolverMock } = {}) {
    const apolloProvider = createMockApolloProvider([[query, resolverMock]]);
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
  const findAutomatedSchedulingGroup = () => wrapper.findAllComponents(GlFormGroup).at(1);
  const findStartDateGroup = () => wrapper.findAllComponents(GlFormGroup).at(2);
  const findDurationGroup = () => wrapper.findAllComponents(GlFormGroup).at(3);
  const findFutureIterationsGroup = () => wrapper.findAllComponents(GlFormGroup).at(5);

  const findError = () => wrapper.findComponent(GlAlert);

  const findTitle = () => wrapper.find('#cadence-title');
  const findStartDate = () => wrapper.find('#cadence-start-date');
  const findFutureIterations = () => wrapper.find('#cadence-schedule-future-iterations');
  const findDuration = () => wrapper.find('#cadence-duration');
  const findDescription = () => wrapper.find('#cadence-description');

  const setTitle = (value) => findTitle().vm.$emit('input', value);
  const setStartDate = (value) => findStartDate().vm.$emit('input', value);
  const setFutureIterations = (value) => findFutureIterations().vm.$emit('input', value);
  const setDuration = (value) => findDuration().vm.$emit('input', value);
  const setAutomaticValue = (value) => {
    const checkbox = findAutomatedSchedulingGroup().find(GlFormCheckbox).vm;
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
    let resolverMock;

    beforeEach(() => {
      resolverMock = jest.fn().mockResolvedValue(createMutationSuccess);
      createComponent({ resolverMock });
    });

    it('cancel button links to list page', () => {
      clickCancel();

      expect(push).toHaveBeenCalledWith({ name: 'index' });
    });

    describe('save', () => {
      const title = 'Iteration 5';
      const startDate = '2020-05-05';
      const durationInWeeks = 2;
      const iterationsInAdvance = 6;

      it('triggers mutation with form data', () => {
        setTitle(title);
        setStartDate(startDate);
        setDuration(durationInWeeks);
        setFutureIterations(iterationsInAdvance);

        clickSave();

        expect(findError().exists()).toBe(false);
        expect(resolverMock).toHaveBeenCalledWith({
          input: {
            groupPath,
            title,
            automatic: true,
            startDate,
            durationInWeeks,
            iterationsInAdvance,
            active: true,
            description: '',
          },
        });
      });

      it('redirects to Iteration page on success', async () => {
        setTitle(title);
        setStartDate(startDate);
        setDuration(durationInWeeks);
        setFutureIterations(iterationsInAdvance);

        clickSave();

        await waitForPromises();

        expect(push).toHaveBeenCalledWith({ name: 'index' });
      });

      it('does not submit if required fields missing', () => {
        clickSave();

        expect(resolverMock).not.toHaveBeenCalled();
        expect(findTitleGroup().text()).toContain('This field is required');
        expect(findStartDateGroup().text()).toContain('This field is required');
        expect(findDurationGroup().text()).toContain('This field is required');
        expect(findFutureIterationsGroup().text()).toContain('This field is required');
      });

      it('loading=false on error', async () => {
        resolverMock = jest.fn().mockResolvedValue(createMutationFailure);
        createComponent({ resolverMock });

        clickSave();

        await waitForPromises();

        expect(findSaveButton().props('loading')).toBe(false);
      });
    });

    describe('automated scheduling disabled', () => {
      it('disables future iterations and duration in weeks', async () => {
        setAutomaticValue(false);

        await nextTick();

        expect(findFutureIterations().attributes('disabled')).toBe('disabled');
        expect(findFutureIterations().attributes('required')).toBeUndefined();
        expect(findDuration().attributes('disabled')).toBe('disabled');
        expect(findDuration().attributes('required')).toBeUndefined();
      });

      it('sets future iterations and cadence duration to 0', async () => {
        const title = 'Iteration 5';
        const startDate = '2020-05-05';

        setFutureIterations(10);
        setDuration(2);

        setAutomaticValue(false);

        await nextTick();

        setTitle(title);
        setStartDate(startDate);

        clickSave();

        expect(resolverMock).toHaveBeenCalledWith({
          input: {
            groupPath,
            title,
            automatic: false,
            startDate,
            durationInWeeks: 0,
            iterationsInAdvance: 0,
            description: '',
            active: true,
          },
        });
      });
    });
  });

  describe('Edit cadence', () => {
    const query = getCadence;
    const resolverMock = jest.fn().mockResolvedValue(getCadenceSuccess);

    beforeEach(() => {
      $router.currentRoute.params.cadenceId = id;

      createComponent({ query, resolverMock });
    });

    afterEach(() => {
      delete $router.currentRoute.params.cadenceId;
    });

    it('shows correct title and button text', () => {
      expect(wrapper.text()).toContain(wrapper.vm.i18n.edit.title);
      expect(wrapper.text()).toContain(wrapper.vm.i18n.edit.save);
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

    it('fills fields with existing cadence info after loading', async () => {
      createComponent({ query, resolverMock });

      await waitForPromises();

      await nextTick();

      expect(findTitle().element.value).toBe(iterationCadence.title);
      expect(findStartDate().element.value).toBe(iterationCadence.startDate);
      expect(findFutureIterations().element.value).toBe(iterationCadence.iterationsInAdvance);
      expect(findDuration().element.value).toBe(iterationCadence.durationInWeeks);
      expect(findDescription().element.value).toBe(iterationCadence.description);
    });
  });
});
