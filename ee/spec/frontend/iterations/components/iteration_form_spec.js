import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import IterationForm from 'ee/iterations/components/iteration_form.vue';
import readIteration from 'ee/iterations/queries/iteration.query.graphql';
import createIteration from 'ee/iterations/queries/iteration_create.mutation.graphql';
import updateIteration from 'ee/iterations/queries/update_iteration.mutation.graphql';
import groupIterationsInCadenceQuery from 'ee/iterations/queries/group_iterations_in_cadence.query.graphql';
import readCadence from 'ee/iterations/queries/iteration_cadence.query.graphql';
import createRouter from 'ee/iterations/router';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { dayAfter, formatDate } from '~/lib/utils/datetime_utility';
import {
  manualIterationCadence as cadence,
  mockGroupIterations,
  mockIterationNode as iteration,
  createMutationSuccess,
  createMutationFailure,
  updateMutationSuccess,
  emptyGroupIterationsSuccess,
  nonEmptyGroupIterationsSuccess,
  readCadenceSuccess,
} from '../mock_data';

const baseUrl = '/cadences/';
const iterationId = getIdFromGraphQLId(iteration.id);
const cadenceId = getIdFromGraphQLId(cadence.id);

function createMockApolloProvider(requestHandlers) {
  Vue.use(VueApollo);

  return createMockApollo(requestHandlers);
}

describe('Iteration Form', () => {
  let wrapper;
  let router;
  const groupPath = 'gitlab-org';

  function createComponent({
    mutationQuery = createIteration,
    mutationResult = createMutationSuccess,
    query = readIteration,
    result = mockGroupIterations,
    resolverMock = jest.fn().mockResolvedValue(mutationResult),
    groupIterationsSuccess = emptyGroupIterationsSuccess,
  } = {}) {
    const apolloProvider = createMockApolloProvider([
      [query, jest.fn().mockResolvedValue(result)],
      [mutationQuery, resolverMock],
      [groupIterationsInCadenceQuery, jest.fn().mockResolvedValue(groupIterationsSuccess)],
      [readCadence, jest.fn().mockResolvedValue(readCadenceSuccess)],
    ]);
    wrapper = extendedWrapper(
      mount(IterationForm, {
        provide: {
          fullPath: groupPath,
          previewMarkdownPath: '',
        },
        apolloProvider,
        router,
      }),
    );
  }

  beforeEach(() => {
    router = createRouter({
      base: baseUrl,
      permissions: { canCreateIteration: true, canEditIteration: true },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findPageTitle = () => wrapper.findComponent({ ref: 'pageTitle' });
  const findTitle = () => wrapper.find('#iteration-title');
  const findDescription = () => wrapper.find('#iteration-description');
  const findStartDate = () => wrapper.find('#iteration-start-date');
  const findDueDate = () => wrapper.find('#iteration-due-date');
  const findSaveButton = () => wrapper.findByTestId('save-iteration');
  const findCancelButton = () => wrapper.findByTestId('cancel-iteration');
  const clickSave = () => findSaveButton().trigger('click');

  describe('New iteration', () => {
    const resolverMock = jest.fn().mockResolvedValue(createMutationSuccess);

    beforeEach(() => {
      router.replace({
        name: 'newIteration',
        params: { cadenceId, iterationId: undefined },
      });
      createComponent({ resolverMock });
    });

    afterEach(() => {
      router.replace({ name: 'index' });
    });

    it('cancel button links to list page', () => {
      expect(findCancelButton().attributes('href')).toBe(baseUrl);
    });

    describe('save', () => {
      it('triggers mutation with form data', async () => {
        const title = 'Iteration 5';
        const description = 'The fifth iteration';
        const startDate = '2020-05-05';
        const dueDate = '2020-05-25';

        findTitle().vm.$emit('input', title);
        findDescription().setValue(description);
        findStartDate().vm.$emit('input', startDate);
        findDueDate().vm.$emit('input', dueDate);

        await clickSave();

        expect(resolverMock).toHaveBeenCalledWith({
          input: {
            groupPath,
            title,
            description,
            iterationsCadenceId: convertToGraphQLId('Iterations::Cadence', cadence.id),
            startDate,
            dueDate,
          },
        });
      });

      it('redirects to Iteration page on success', async () => {
        createComponent();

        await clickSave();

        expect(findSaveButton().props('loading')).toBe(true);

        await waitForPromises();

        expect(router.currentRoute.name).toBe('iteration');
        expect(router.currentRoute.params).toEqual({
          cadenceId,
          iterationId,
        });
      });

      it('loading=false on error', () => {
        createComponent({ mutationResult: createMutationFailure });

        clickSave();

        return waitForPromises().then(() => {
          expect(findSaveButton().props('loading')).toBe(false);
        });
      });
    });

    describe('prefill start date field', () => {
      describe('cadence with iterations', () => {
        it('starts next day after the last iteration', async () => {
          await createComponent({
            groupIterationsSuccess: nonEmptyGroupIterationsSuccess,
          });

          await waitForPromises();

          const expectedDate = formatDate(
            dayAfter(new Date(iteration.dueDate), { utc: true }),
            'yyyy-mm-dd',
          );

          expect(findStartDate().element.value).toBe(expectedDate);
        });
      });

      describe('manual cadence without iterations', () => {
        beforeEach(async () => {
          await createComponent({
            groupIterationsSuccess: emptyGroupIterationsSuccess,
          });

          await waitForPromises();
        });

        it('uses cadence start date', () => {
          const expectedDate = cadence.startDate;

          expect(findStartDate().element.value).toBe(expectedDate);
        });
      });
    });
  });

  describe('Edit iteration', () => {
    beforeEach(() => {
      router.replace({
        name: 'editIteration',
        params: { cadenceId: cadence.id, iterationId: iteration.id },
      });
    });

    afterEach(() => {
      router.replace({ name: 'index' });
    });

    it('shows update text title', () => {
      createComponent();

      expect(findPageTitle().text()).toBe('Edit iteration');
    });

    it('prefills form fields', async () => {
      createComponent();

      await waitForPromises();

      expect(findTitle().element.value).toBe(iteration.title);
      expect(findDescription().element.value).toBe(iteration.description);
      expect(findStartDate().element.value).toBe(iteration.startDate);
      expect(findDueDate().element.value).toBe(iteration.dueDate);
    });

    it('shows update text on submit button', () => {
      createComponent();

      expect(findSaveButton().text()).toBe('Update iteration');
    });

    it('triggers mutation with form data', async () => {
      const resolverMock = jest.fn().mockResolvedValue(updateMutationSuccess);
      createComponent({ mutationQuery: updateIteration, resolverMock });

      const title = 'Updated title';
      const description = 'Updated description';
      const startDate = '2020-05-06';
      const dueDate = '2020-05-26';

      findTitle().vm.$emit('input', title);
      findDescription().setValue(description);
      findStartDate().vm.$emit('input', startDate);
      findDueDate().vm.$emit('input', dueDate);

      clickSave();
      await waitForPromises();

      expect(resolverMock).toHaveBeenCalledWith({
        input: {
          groupPath,
          id: iteration.id,
          title,
          description,
          startDate,
          dueDate,
        },
      });
    });

    it('calls update mutation', async () => {
      const resolverMock = jest.fn().mockResolvedValue(updateMutationSuccess);
      createComponent({
        mutationQuery: updateIteration,
        resolverMock,
      });

      clickSave();
      await nextTick();
      expect(findSaveButton().props('loading')).toBe(true);

      await waitForPromises();

      expect(resolverMock).toHaveBeenCalledWith({
        input: {
          groupPath,
          id: iteration.id,
          startDate: '',
          dueDate: '',
          title: '',
          description: '',
        },
      });
    });
  });
});
