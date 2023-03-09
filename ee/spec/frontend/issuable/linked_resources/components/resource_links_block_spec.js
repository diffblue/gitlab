import { GlLoadingIcon } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import ResourceLinksBlock from 'ee/linked_resources/components/resource_links_block.vue';
import ResourceLinksList from 'ee/linked_resources/components/resource_links_list.vue';
import ResourceLinkItem from 'ee/linked_resources/components/resource_links_list_item.vue';
import AddIssuableResourceLinkForm from 'ee/linked_resources/components/add_issuable_resource_link_form.vue';
import getIssuableResourceLinks from 'ee/linked_resources/components/graphql/queries/get_issuable_resource_links.query.graphql';
import deleteIssuableResourceLink from 'ee/linked_resources/components/graphql/queries/delete_issuable_resource_link.mutation.graphql';
import createIssuableResourceLink from 'ee/linked_resources/components/graphql/queries/create_issuable_resource_link.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createAlert } from '~/alert';
import {
  mockResourceLinks,
  resourceLinksListResponse,
  resourceLinksEmptyResponse,
  resourceLinksDeleteEventResponse,
  resourceLinkDeleteEventError,
  resourceLinkCreateEventResponse,
  resourceLinkCreateEventError,
} from './mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

const grapqhQlError = new Error('GraphQL Error');
const userInput = {
  id: 'gid://gitlab/Issue/1',
  link: 'https://gitlab.zoom.us/j/incident-triage',
  linkText: 'Demo incident link',
  linkType: 'zoom',
};
const listResponse = jest.fn().mockResolvedValue(resourceLinksListResponse);
const emptyResponse = jest.fn().mockResolvedValue(resourceLinksEmptyResponse);
const errorResponse = jest.fn().mockRejectedValue(grapqhQlError);
const deleteResponse = jest.fn();
const createResponse = jest.fn();

function createMockApolloProvider(response = emptyResponse) {
  const requestHandlers = [[getIssuableResourceLinks, response]];
  return createMockApollo(requestHandlers);
}

function createMockApolloDeleteProvider() {
  deleteResponse.mockResolvedValue(resourceLinksDeleteEventResponse);
  const requestHandlers = [[deleteIssuableResourceLink, deleteResponse]];
  return createMockApollo(requestHandlers);
}

function createMockApolloCreateProvider() {
  createResponse.mockResolvedValue(resourceLinkCreateEventResponse);
  const requestHandlers = [[createIssuableResourceLink, createResponse]];
  return createMockApollo(requestHandlers);
}

describe('ResourceLinksBlock', () => {
  let wrapper;

  const findResourceLinkAddButton = () => wrapper.findByTestId('add-resource-links');
  const resourceLinkForm = () => wrapper.findComponent(AddIssuableResourceLinkForm);
  const helpPath = '/help/user/project/issues/linked_resources';
  const issuableId = 1;
  const findLoadingSpinner = () => wrapper.findComponent(GlLoadingIcon);
  const findResourceLinksList = () => wrapper.findComponent(ResourceLinksList);
  const findAllResourceLinks = () => wrapper.findAllComponents(ResourceLinkItem);
  const findLinkTextInput = () => wrapper.findByTestId('link-text-input');
  const findLinkValueInput = () => wrapper.findByTestId('link-value-input');
  const findSubmitButton = () => wrapper.findByTestId('add-button');

  const clickFirstDeleteButton = async () => {
    findAllResourceLinks().at(0).vm.$emit('removeRequest', mockResourceLinks[0].id);

    await waitForPromises();
  };

  const openForm = async () => {
    findResourceLinkAddButton().trigger('click');
    await waitForPromises();
  };

  const fillData = () => {
    findLinkTextInput().setValue(userInput.linkText);
    findLinkValueInput().setValue(userInput.link);
  };

  const submitForm = async () => {
    await openForm();

    fillData();
    await nextTick();

    findSubmitButton().trigger('click');
    await waitForPromises();
  };

  const mountComponent = (mockApollo = createMockApolloProvider(), resourceLinks = []) => {
    wrapper = mountExtended(ResourceLinksBlock, {
      propsData: {
        issuableId,
        helpPath,
        canAddResourceLinks: true,
      },
      apolloProvider: mockApollo,
      data() {
        return {
          resourceLinks,
          isFormVisible: false,
        };
      },
    });
  };

  describe('with defaults', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('should show the form when add button is clicked', async () => {
      await findResourceLinkAddButton().trigger('click');

      expect(resourceLinkForm().isVisible()).toBe(true);
    });

    it('should hide the form when the hide event is emitted', async () => {
      // open the form
      await findResourceLinkAddButton().trigger('click');

      await resourceLinkForm().vm.$emit('add-issuable-resource-link-form-cancel');

      expect(resourceLinkForm().isVisible()).toBe(false);
    });
  });

  describe('with canAddResourceLinks=false', () => {
    it('does not show the add button', () => {
      wrapper = shallowMountExtended(ResourceLinksBlock, {
        propsData: {
          issuableId,
          canAddResourceLinks: false,
        },
        apolloProvider: createMockApolloProvider(),
      });

      expect(findResourceLinkAddButton().exists()).toBe(false);
      expect(resourceLinkForm().isVisible()).toBe(false);
    });
  });

  describe('with isFormVisible=true', () => {
    it('renders the form with correct props', () => {
      wrapper = shallowMount(ResourceLinksBlock, {
        propsData: {
          issuableId,
          canAddResourceLinks: true,
        },
        data() {
          return {
            isFormVisible: true,
            isSubmitting: false,
          };
        },
        apolloProvider: createMockApolloProvider(),
      });

      expect(resourceLinkForm().exists()).toBe(true);
      expect(resourceLinkForm().props('isSubmitting')).toBe(false);
    });
  });

  describe('empty state', () => {
    let mockApollo;

    it('should not show list view', async () => {
      mockApollo = createMockApolloProvider();
      mountComponent(mockApollo);
      await waitForPromises();

      expect(findResourceLinksList().exists()).toBe(false);
    });
  });

  describe('error state', () => {
    let mockApollo;

    it('should show an error state', async () => {
      mockApollo = createMockApolloProvider(errorResponse);
      mountComponent(mockApollo);
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        captureError: true,
        error: grapqhQlError,
        message: 'Something went wrong while fetching linked resources for the incident.',
      });
    });
  });

  describe('resourceLinksQuery', () => {
    let mockApollo;

    it('should request data', () => {
      mockApollo = createMockApolloProvider(listResponse);
      mountComponent(mockApollo);

      expect(listResponse).toHaveBeenCalled();
    });

    it('should show the loading state and correct badgeLabel', () => {
      mockApollo = createMockApolloProvider(listResponse);
      mountComponent(mockApollo);

      expect(findResourceLinksList().exists()).toBe(false);
      expect(findLoadingSpinner().exists()).toBe(true);
      expect(wrapper.vm.badgeLabel).toBe('...');
    });

    it('should render the list and count', async () => {
      mockApollo = createMockApolloProvider(listResponse);
      mountComponent(mockApollo);

      await waitForPromises();

      expect(findResourceLinksList().exists()).toBe(true);
      expect(wrapper.vm.badgeLabel).toBe(3);
      expect(findResourceLinksList().props('resourceLinks')).toHaveLength(3);
    });
  });

  describe('delete mutation', () => {
    it('should delete when button is clicked and update list', async () => {
      const expectedVars = { input: { id: mockResourceLinks[0].id } };

      mountComponent(createMockApolloDeleteProvider(), mockResourceLinks);

      await clickFirstDeleteButton();

      expect(deleteResponse).toHaveBeenCalledWith(expectedVars);
      expect(findAllResourceLinks().length).toBe(2);
    });

    it('should show an error when delete returns an error', async () => {
      const expectedError = {
        message: 'Error deleting the linked resource for the incident: Item does not exist',
        captureError: false,
        error: null,
      };

      mountComponent(createMockApolloDeleteProvider(), mockResourceLinks);
      deleteResponse.mockResolvedValue(resourceLinkDeleteEventError);

      await clickFirstDeleteButton();

      expect(createAlert).toHaveBeenCalledWith(expectedError);
    });

    it('should show an error when delete fails', async () => {
      const expectedError = {
        message: 'Something went wrong while deleting the linked resource for the incident.',
        error: new Error(),
        captureError: true,
      };

      mountComponent(createMockApolloDeleteProvider(), mockResourceLinks);
      deleteResponse.mockRejectedValueOnce();

      await clickFirstDeleteButton();

      expect(createAlert).toHaveBeenCalledWith(expectedError);
      expect(findAllResourceLinks().length).toBe(3);
    });
  });

  describe('createMutation', () => {
    const expectedData = {
      input: userInput,
    };

    it('should call the mutation with right variables and closes the form', async () => {
      mountComponent(createMockApolloCreateProvider());

      await submitForm();

      expect(createResponse).toHaveBeenCalledWith(expectedData);
      expect(resourceLinkForm().isVisible()).toBe(false);
    });

    describe('error handling', () => {
      it.each`
        mockReject | message                                                                      | captureError | error
        ${true}    | ${'Something went wrong while creating the resource link for the incident.'} | ${true}      | ${new Error()}
        ${false}   | ${'Error creating resource link for the incident: Create error'}             | ${false}     | ${null}
      `(
        'should show an error when submission fails',
        async ({ mockReject, message, captureError, error }) => {
          const expectedAlertArgs = {
            captureError,
            error,
            message,
          };
          mountComponent(createMockApolloCreateProvider(), mockResourceLinks);
          if (mockReject) {
            createResponse.mockRejectedValueOnce();
          } else {
            createResponse.mockResolvedValue(resourceLinkCreateEventError);
          }

          await submitForm();

          expect(createAlert).toHaveBeenCalledWith(expectedAlertArgs);
        },
      );
    });
  });
});
