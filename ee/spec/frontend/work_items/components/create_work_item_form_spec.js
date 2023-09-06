import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlButton, GlForm, GlFormCheckbox, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CreateWorkItemForm from 'ee/work_items/components/create_work_item_form.vue';
import { __ } from '~/locale';
import { WORK_ITEM_TYPE_VALUE_OBJECTIVE } from '~/work_items/constants';
import groupWorkItemTypesQuery from '~/work_items/graphql/group_work_item_types.query.graphql';
import projectWorkItemTypesQuery from '~/work_items/graphql/project_work_item_types.query.graphql';
import createWorkItemMutation from '~/work_items/graphql/create_work_item.mutation.graphql';
import {
  groupOrProjectWorkItemTypesQueryResponse,
  createWorkItemMutationResponse,
  createWorkItemMutationErrorResponse,
} from '../mock_data';

Vue.use(VueApollo);

describe('Create work item Objective component', () => {
  let wrapper;

  const groupQuerySuccessHandler = jest
    .fn()
    .mockResolvedValue(groupOrProjectWorkItemTypesQueryResponse);
  const projectQuerySuccessHandler = jest
    .fn()
    .mockResolvedValue(groupOrProjectWorkItemTypesQueryResponse);
  const mutationSuccessHandler = jest.fn().mockResolvedValue(createWorkItemMutationResponse);
  const mutationErrorHandler = jest.fn().mockResolvedValue(createWorkItemMutationErrorResponse);

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findForm = () => wrapper.findComponent(GlForm);
  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findTitleInput = () => wrapper.findComponent(GlFormInput);
  const findConfidentialityToggle = () => wrapper.findComponent(GlFormCheckbox);
  const findCreateButton = () => wrapper.findComponent(GlButton);
  const submitForm = async () => {
    findForm().vm.$emit('submit', { preventDefault: jest.fn() });
    await waitForPromises();
  };

  const createComponent = ({
    isGroup = false,
    groupQueryHandler = groupQuerySuccessHandler,
    projectQueryHandler = projectQuerySuccessHandler,
    mutationHandler = mutationSuccessHandler,
  } = {}) => {
    wrapper = shallowMount(CreateWorkItemForm, {
      apolloProvider: createMockApollo([
        [groupWorkItemTypesQuery, groupQueryHandler],
        [projectWorkItemTypesQuery, projectQueryHandler],
        [createWorkItemMutation, mutationHandler],
      ]),
      propsData: {
        isGroup,
        workItemType: WORK_ITEM_TYPE_VALUE_OBJECTIVE,
      },
      provide: {
        fullPath: 'full-path',
      },
    });
  };

  describe('form controls', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders title input', () => {
      expect(findTitleInput().attributes('placeholder')).toBe(__('Title'));
    });

    it('renders title label', () => {
      expect(findFormGroup().attributes('label')).toBe(__('Title'));
      expect(findFormGroup().attributes('label-for')).toBe(findTitleInput().attributes('id'));
    });

    it('renders confidentiality toggle checkbox', () => {
      expect(findConfidentialityToggle().text()).toBe(
        'This objective is confidential and should only be visible to team members with at least Reporter access',
      );
    });
  });

  it('does not render error by default', () => {
    createComponent();

    expect(findAlert().exists()).toBe(false);
  });

  it('renders a disabled create button when title input is empty', () => {
    createComponent();

    expect(findCreateButton().props('disabled')).toBe(true);
  });

  it('hides the alert on dismissing the error', async () => {
    createComponent({ projectQueryHandler: jest.fn().mockRejectedValue('oh no') });
    await waitForPromises();

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

      expect(mutationSuccessHandler).toHaveBeenCalledWith({
        input: {
          title: mockTitle,
          confidential: false,
          namespacePath: 'full-path',
        },
      });
    });

    it('calls mutation with confidentiality set on form submission', async () => {
      findConfidentialityToggle().vm.$emit('input', true);
      await submitForm();

      expect(mutationSuccessHandler).toHaveBeenCalledWith({
        input: {
          title: mockTitle,
          confidential: true,
          namespacePath: 'full-path',
        },
      });
    });

    it('renders an enabled create button', () => {
      expect(findCreateButton().props('disabled')).toBe(false);
    });
  });

  describe('work item types query', () => {
    describe('when project context', () => {
      beforeEach(() => {
        createComponent({ isGroup: false });
      });

      it('calls project query', () => {
        expect(projectQuerySuccessHandler).toHaveBeenCalled();
      });

      it('does not call group query', () => {
        expect(groupQuerySuccessHandler).not.toHaveBeenCalled();
      });
    });

    describe('when group context', () => {
      beforeEach(() => {
        createComponent({ isGroup: true });
      });

      it('calls group query', () => {
        expect(groupQuerySuccessHandler).toHaveBeenCalled();
      });

      it('does not call project query', () => {
        expect(projectQuerySuccessHandler).not.toHaveBeenCalled();
      });
    });
  });

  it('shows an alert on mutation error', async () => {
    createComponent({ mutationHandler: mutationErrorHandler });
    await waitForPromises();

    findTitleInput().vm.$emit('input', 'some title');
    await submitForm();

    expect(findAlert().text()).toBe('Title is too long (maximum is 255 characters)');
  });
});
