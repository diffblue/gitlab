import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlFormInput } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CreateWorkItemObjective from 'ee/work_items/components/create_work_item_objective.vue';
import projectWorkItemTypesQuery from '~/work_items/graphql/project_work_item_types.query.graphql';
import createWorkItemMutation from '~/work_items/graphql/create_work_item.mutation.graphql';
import { projectWorkItemTypesQueryResponse, createWorkItemMutationResponse } from '../mock_data';

Vue.use(VueApollo);

describe('Create work item Objective component', () => {
  let wrapper;
  let fakeApollo;

  const querySuccessHandler = jest.fn().mockResolvedValue(projectWorkItemTypesQueryResponse);
  const createWorkItemSuccessHandler = jest.fn().mockResolvedValue(createWorkItemMutationResponse);
  const errorHandler = jest.fn().mockRejectedValue('Houston, we have a problem');

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findTitleInput = () => wrapper.findComponent(GlFormInput);
  const findCreateButton = () => wrapper.find('[data-testid="create-button"]');

  const createComponent = ({
    data = {},
    props = {},
    queryHandler = querySuccessHandler,
    mutationHandler = createWorkItemSuccessHandler,
    fetchByIid = false,
  } = {}) => {
    fakeApollo = createMockApollo(
      [
        [projectWorkItemTypesQuery, queryHandler],
        [createWorkItemMutation, mutationHandler],
      ],
      {},
      { typePolicies: { Project: { merge: true } } },
    );
    wrapper = shallowMount(CreateWorkItemObjective, {
      apolloProvider: fakeApollo,
      data() {
        return {
          ...data,
        };
      },
      propsData: {
        ...props,
      },
      mocks: {
        $router: {
          go: jest.fn(),
        },
      },
      provide: {
        fullPath: 'full-path',
        glFeatures: {
          useIidInWorkItemsPath: fetchByIid,
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    fakeApollo = null;
  });

  it('does not render error by default', () => {
    createComponent();

    expect(findAlert().exists()).toBe(false);
  });

  it('renders a disabled Create button when title input is empty', () => {
    createComponent();

    expect(findCreateButton().props('disabled')).toBe(true);
  });

  it('hides the alert on dismissing the error', async () => {
    createComponent({ data: { error: true } });

    expect(findAlert().exists()).toBe(true);

    findAlert().vm.$emit('dismiss');
    await nextTick();

    expect(findAlert().exists()).toBe(false);
  });

  describe('when title input field has a text', () => {
    beforeEach(async () => {
      const mockTitle = 'Test title';
      createComponent();
      await waitForPromises();
      findTitleInput().vm.$emit('input', mockTitle);
    });

    it('renders a enabled Create button', () => {
      expect(findCreateButton().props('disabled')).toBe(false);
    });
  });

  it('shows an alert on mutation error', async () => {
    createComponent({ mutationHandler: errorHandler });
    await waitForPromises();

    findTitleInput().vm.$emit('input', 'some title');
    wrapper.find('form').trigger('submit');
    await waitForPromises();

    expect(findAlert().text()).toBe(
      'Something went wrong when creating work item. Please try again.',
    );
  });
});
