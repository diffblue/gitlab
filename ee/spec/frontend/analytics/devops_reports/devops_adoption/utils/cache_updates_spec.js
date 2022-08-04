import {
  deleteEnabledNamespacesFromCache,
  addEnabledNamespacesToCache,
} from 'ee/analytics/devops_reports/devops_adoption/utils/cache_updates';
import { devopsAdoptionNamespaceData } from '../mock_data';

describe('addEnabledNamespacesToCache', () => {
  const store = {
    readQuery: jest.fn(() => ({ devopsAdoptionEnabledNamespaces: { nodes: [] } })),
    writeQuery: jest.fn(),
  };

  it('calls writeQuery with the correct response', () => {
    addEnabledNamespacesToCache(store, devopsAdoptionNamespaceData.nodes);

    expect(store.writeQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        data: {
          devopsAdoptionEnabledNamespaces: {
            nodes: devopsAdoptionNamespaceData.nodes,
          },
        },
      }),
    );
  });
});

describe('deleteEnabledNamespacesFromCache', () => {
  const store = {
    readQuery: jest.fn(() => ({ devopsAdoptionEnabledNamespaces: devopsAdoptionNamespaceData })),
    writeQuery: jest.fn(),
  };

  it('calls writeQuery with the correct response', () => {
    // Remove the item at the first index
    deleteEnabledNamespacesFromCache(store, [devopsAdoptionNamespaceData.nodes[0].id]);

    expect(store.writeQuery).toHaveBeenCalledWith(
      expect.not.objectContaining({
        data: {
          devopsAdoptionEnabledNamespaces: {
            __typename: 'DevopsAdoptionEnabledNamespaceConnection',
            nodes: devopsAdoptionNamespaceData.nodes,
          },
        },
      }),
    );

    expect(store.writeQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        data: {
          devopsAdoptionEnabledNamespaces: {
            __typename: 'DevopsAdoptionEnabledNamespaceConnection',
            // Remove the item at the first index
            nodes: devopsAdoptionNamespaceData.nodes.slice(1),
          },
        },
      }),
    );
  });
});
