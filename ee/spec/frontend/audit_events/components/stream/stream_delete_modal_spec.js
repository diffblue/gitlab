import { GlSprintf, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';

import StreamDeleteModal from 'ee/audit_events/components/stream/stream_delete_modal.vue';
import deleteExternalDestination from 'ee/audit_events/graphql/mutations/delete_external_destination.mutation.graphql';
import deleteInstanceExternalDestination from 'ee/audit_events/graphql/mutations/delete_instance_external_destination.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  groupPath,
  destinationDeleteMutationPopulator,
  mockExternalDestinations,
  instanceGroupPath,
  destinationInstanceDeleteMutationPopulator,
  mockInstanceExternalDestinations,
} from '../../mock_data';

Vue.use(VueApollo);

describe('StreamDeleteModal', () => {
  let wrapper;

  const instanceDestination = mockInstanceExternalDestinations[0];
  const deleteSuccess = jest.fn().mockResolvedValue(destinationDeleteMutationPopulator());
  const deleteInstanceSuccess = jest
    .fn()
    .mockResolvedValue(destinationInstanceDeleteMutationPopulator());
  const deleteError = jest
    .fn()
    .mockResolvedValue(destinationDeleteMutationPopulator(['Random Error message']));
  const deleteNetworkError = jest
    .fn()
    .mockRejectedValue(destinationDeleteMutationPopulator(['Network error']));

  let groupPathProvide = groupPath;
  let itemProvide = mockExternalDestinations[0];
  let deleteExternalDestinationProvide = deleteExternalDestination;

  const findModal = () => wrapper.findComponent(GlModal);
  const clickDeleteFramework = () => findModal().vm.$emit('primary');

  const createComponent = (resolverMock) => {
    const mockApollo = createMockApollo([[deleteExternalDestinationProvide, resolverMock]]);

    wrapper = shallowMount(StreamDeleteModal, {
      apolloProvider: mockApollo,
      propsData: {
        item: itemProvide,
      },
      provide: {
        groupPath: groupPathProvide,
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

    it('sets the modal id', () => {
      expect(findModal().props('modalId')).toBe('delete-destination-modal');
    });

    it('sets the modal primary button attributes', () => {
      const actionPrimary = findModal().props('actionPrimary');

      expect(actionPrimary.text).toBe('Delete destination');
      expect(actionPrimary.attributes.variant).toBe('danger');
    });

    it('sets the modal cancel button attributes', () => {
      expect(findModal().props('actionCancel').text).toBe('Cancel');
    });
  });

  describe('Group clickDeleteDestination', () => {
    it('emits "deleting" event when busy deleting', () => {
      createComponent();
      clickDeleteFramework();

      expect(wrapper.emitted('deleting')).toHaveLength(1);
    });

    it('calls the delete mutation with the destination ID', async () => {
      createComponent(deleteSuccess);
      clickDeleteFramework();

      await waitForPromises();

      expect(deleteSuccess).toHaveBeenCalledWith({
        id: mockExternalDestinations[0].id,
        isInstance: false,
      });
    });

    it('emits "delete" event when the destination is successfully deleted', async () => {
      createComponent(deleteSuccess);
      clickDeleteFramework();

      await waitForPromises();

      expect(wrapper.emitted('delete')).toHaveLength(1);
    });

    it('emits "error" event when there is a network error', async () => {
      createComponent(deleteNetworkError);
      clickDeleteFramework();

      await waitForPromises();

      expect(wrapper.emitted('error')).toHaveLength(1);
    });

    it('emits "error" event when there is a graphql error', async () => {
      createComponent(deleteError);
      clickDeleteFramework();

      await waitForPromises();

      expect(wrapper.emitted('error')).toHaveLength(1);
    });
  });

  describe('Instance clickDeleteDestination', () => {
    beforeEach(() => {
      groupPathProvide = instanceGroupPath;
      itemProvide = instanceDestination;
      deleteExternalDestinationProvide = deleteInstanceExternalDestination;
    });

    it('emits "deleting" event when busy deleting', () => {
      createComponent();
      clickDeleteFramework();

      expect(wrapper.emitted('deleting')).toHaveLength(1);
    });

    it('calls the delete mutation with the destination ID', async () => {
      createComponent(deleteInstanceSuccess);
      clickDeleteFramework();

      await waitForPromises();

      expect(deleteInstanceSuccess).toHaveBeenCalledWith({
        id: mockExternalDestinations[0].id,
        isInstance: true,
      });
    });

    it('emits "delete" event when the destination is successfully deleted', async () => {
      createComponent(deleteInstanceSuccess);
      clickDeleteFramework();

      await waitForPromises();

      expect(wrapper.emitted('delete')).toHaveLength(1);
    });

    it('emits "error" event when there is a network error', async () => {
      createComponent(deleteNetworkError);
      clickDeleteFramework();

      await waitForPromises();

      expect(wrapper.emitted('error')).toHaveLength(1);
    });

    it('emits "error" event when there is a graphql error', async () => {
      createComponent(deleteError);
      clickDeleteFramework();

      await waitForPromises();

      expect(wrapper.emitted('error')).toHaveLength(1);
    });
  });
});
