import { GlSprintf, GlModal } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';

import DeleteModal from 'ee/groups/settings/compliance_frameworks/components/delete_modal.vue';
import deleteComplianceFrameworkMutation from 'ee/groups/settings/compliance_frameworks/graphql/mutations/delete_compliance_framework.mutation.graphql';
import getComplianceFrameworkQuery from 'ee/graphql_shared/queries/get_compliance_framework.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  validFetchResponse,
  validDeleteResponse,
  errorDeleteResponse,
  frameworkFoundResponse,
} from '../mock_data';

Vue.use(VueApollo);

describe('DeleteModal', () => {
  let wrapper;

  const fetchSuccess = jest.fn().mockResolvedValue(validFetchResponse);
  const networkError = new Error('network error');
  const deleteSuccess = jest.fn().mockResolvedValue(validDeleteResponse);
  const deleteError = jest.fn().mockResolvedValue(errorDeleteResponse);
  const deleteNetworkError = jest.fn().mockRejectedValue(networkError);

  const findModal = () => wrapper.findComponent(GlModal);
  const clickDeleteFramework = () => findModal().vm.$emit('primary');

  function createMockApolloProvider(resolverMock) {
    Vue.use(VueApollo);

    const requestHandlers = [
      [getComplianceFrameworkQuery, fetchSuccess],
      [deleteComplianceFrameworkMutation, resolverMock],
    ];

    return createMockApollo(requestHandlers);
  }

  const createComponent = (resolverMock) => {
    wrapper = shallowMount(DeleteModal, {
      apolloProvider: createMockApolloProvider(resolverMock),
      propsData: {
        name: frameworkFoundResponse.name,
        id: frameworkFoundResponse.id,
      },
      provide: {
        groupPath: 'group-1',
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  describe('component layout', () => {
    beforeEach(() => {
      createComponent();
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('sets the modal id', () => {
      expect(findModal().props('modalId')).toBe('delete-framework-modal');
    });

    it('sets the modal primary button attributes', () => {
      const actionPrimary = findModal().props('actionPrimary');

      expect(actionPrimary.text).toBe('Delete framework');
      expect(actionPrimary.attributes.variant).toBe('danger');
    });

    it('sets the modal cancel button attributes', () => {
      expect(findModal().props('actionCancel').text).toBe('Cancel');
    });
  });

  describe('clickDeleteFramework', () => {
    it('emits "deleting" event when busy deleting', () => {
      createComponent();
      clickDeleteFramework();

      expect(wrapper.emitted('deleting')).toHaveLength(1);
    });

    it('calls the delete mutation with the framework ID', async () => {
      createComponent(deleteSuccess);
      clickDeleteFramework();

      await waitForPromises();

      expect(deleteSuccess).toHaveBeenCalledWith({ input: { id: frameworkFoundResponse.id } });
    });

    it('calls the fetch query with the groupPath', async () => {
      createComponent(deleteSuccess);
      clickDeleteFramework();

      await waitForPromises();

      expect(fetchSuccess).toHaveBeenCalledWith({ fullPath: 'group-1' });
    });

    it('emits "delete" event when the framework is successfully deleted', async () => {
      createComponent(deleteSuccess);
      clickDeleteFramework();

      await waitForPromises();

      expect(wrapper.emitted('delete')[0]).toEqual([frameworkFoundResponse.id]);
    });

    it('emits "error" event and reports to Sentry when there is a network error', async () => {
      jest.spyOn(Sentry, 'captureException');
      createComponent(deleteNetworkError);
      clickDeleteFramework();

      await waitForPromises();

      expect(wrapper.emitted('error')).toHaveLength(1);
      expect(Sentry.captureException.mock.calls[0][0].networkError).toStrictEqual(networkError);
    });

    it('emits "error" event and reports to Sentry when there is a graphql error', async () => {
      jest.spyOn(Sentry, 'captureException');
      createComponent(deleteError);
      clickDeleteFramework();

      await waitForPromises();

      expect(wrapper.emitted('error')).toHaveLength(1);
      expect(Sentry.captureException.mock.calls[0][0]).toStrictEqual(new Error('graphql error'));
    });
  });
});
