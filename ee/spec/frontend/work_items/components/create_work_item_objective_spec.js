import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlForm, GlFormCheckbox, GlFormInput } from '@gitlab/ui';
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
  const findForm = () => wrapper.findComponent(GlForm);
  const findTitleInput = () => wrapper.findComponent(GlFormInput);
  const findConfidentialityToggle = () => wrapper.findComponent(GlFormCheckbox);
  const findCreateButton = () => wrapper.find('[data-testid="create-button"]');
  const submitForm = async () => {
    findForm().vm.$emit('submit', { preventDefault: jest.fn() });
    await waitForPromises();
  };

  const createComponent = ({
    data = {},
    props = {},
    queryHandler = querySuccessHandler,
    mutationHandler = createWorkItemSuccessHandler,
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
      },
    });
  };

  afterEach(() => {
    fakeApollo = null;
  });

  describe('gl-form', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders title input', () => {
      const titleEl = findTitleInput();
      expect(titleEl.exists()).toBe(true);
      expect(titleEl.attributes('placeholder')).toBe('Title');
    });

    it('renders confidentiality toggle checkbox', () => {
      const checkboxEl = findConfidentialityToggle();
      expect(checkboxEl.exists()).toBe(true);
      expect(checkboxEl.text()).toBe(
        'This objective is confidential and should only be visible to team members with at least Reporter access',
      );
    });
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
    const mockTitle = 'Test title';

    beforeEach(async () => {
      createComponent();
      await waitForPromises();
      findTitleInput().vm.$emit('input', mockTitle);
    });

    it('calls mutation with provided title on form submission', async () => {
      await submitForm();

      expect(createWorkItemSuccessHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          input: {
            title: mockTitle,
            confidential: false,
            projectPath: 'full-path',
          },
        }),
      );
    });

    it('calls mutation with confidentiality set on form submission', async () => {
      findConfidentialityToggle().vm.$emit('input', true);
      await submitForm();

      expect(createWorkItemSuccessHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          input: {
            title: mockTitle,
            confidential: true,
            projectPath: 'full-path',
          },
        }),
      );
    });

    it('renders a enabled Create button', () => {
      expect(findCreateButton().props('disabled')).toBe(false);
    });
  });

  it('shows an alert on mutation error', async () => {
    createComponent({ mutationHandler: errorHandler });
    await waitForPromises();

    findTitleInput().vm.$emit('input', 'some title');
    await submitForm();

    expect(findAlert().text()).toBe(
      'Something went wrong when creating work item. Please try again.',
    );
  });
});
