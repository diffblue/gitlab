import { InMemoryCache } from '@apollo/client/core';
import {
  addAuditEventsStreamingDestination,
  removeAuditEventsStreamingDestination,
  addAuditEventStreamingHeader,
  removeAuditEventStreamingHeader,
  updateEventTypeFilters,
  removeEventTypeFilters,
} from 'ee/audit_events/graphql/cache_update';
import externalDestinationsQuery from 'ee/audit_events/graphql/queries/get_external_destinations.query.graphql';
import {
  mockExternalDestinations,
  destinationDataPopulator,
  destinationCreateMutationPopulator,
  destinationHeaderCreateMutationPopulator,
} from '../mock_data';

describe('Audit Events GraphQL cache updates', () => {
  const GROUP1_PATH = 'group-1';
  const GROUP2_PATH = 'group-2';
  const GROUP_NOT_IN_CACHE = 'other-group';
  let cache;

  const getMockDestination = (id) =>
    destinationDataPopulator(
      mockExternalDestinations.map((record) => ({ ...record, id: `${record.id}-set-${id}` })),
    );

  const getDestinations = (fullPath) =>
    cache.readQuery({
      query: externalDestinationsQuery,
      variables: { fullPath },
    }).group.externalAuditEventDestinations.nodes;

  beforeEach(() => {
    cache = new InMemoryCache();

    cache.writeQuery({
      query: externalDestinationsQuery,
      variables: { fullPath: GROUP1_PATH },
      data: getMockDestination(GROUP1_PATH).data,
    });

    cache.writeQuery({
      query: externalDestinationsQuery,
      variables: { fullPath: GROUP2_PATH },
      data: getMockDestination(GROUP2_PATH).data,
    });
  });

  describe('addAuditEventsStreamingDestination', () => {
    const {
      externalAuditEventDestination: newDestination,
    } = destinationCreateMutationPopulator().data.externalAuditEventDestinationCreate;

    it('adds new destination to list of destinations for specific fullPath', () => {
      const { length: originalDestinationsLengthForGroup1 } = getDestinations(GROUP1_PATH);
      const { length: originalDestinationsLengthForGroup2 } = getDestinations(GROUP2_PATH);

      addAuditEventsStreamingDestination({
        store: cache,
        fullPath: GROUP1_PATH,
        newDestination,
      });

      expect(getDestinations(GROUP1_PATH)).toHaveLength(originalDestinationsLengthForGroup1 + 1);
      expect(getDestinations(GROUP1_PATH)).toStrictEqual(
        expect.arrayContaining([expect.objectContaining({ id: newDestination.id })]),
      );
      expect(getDestinations(GROUP2_PATH)).toHaveLength(originalDestinationsLengthForGroup2);
    });

    it('does not throw on non-existing fullPath', () => {
      expect(() =>
        addAuditEventsStreamingDestination({
          store: cache,
          fullPath: GROUP_NOT_IN_CACHE,
          newDestination,
        }),
      ).not.toThrow();
    });
  });

  describe('removeAuditEventsStreamingDestination', () => {
    it('removes new destination to list of destinations for specific fullPath', () => {
      const [firstDestination, ...restDestinations] = getDestinations(GROUP1_PATH);
      const { length: originalDestinationsLengthForGroup2 } = getDestinations(GROUP2_PATH);

      removeAuditEventsStreamingDestination({
        store: cache,
        fullPath: GROUP1_PATH,
        destinationId: firstDestination.id,
      });

      expect(getDestinations(GROUP1_PATH)).toHaveLength(restDestinations.length);
      expect(getDestinations(GROUP1_PATH)).not.toStrictEqual(
        expect.arrayContaining([expect.objectContaining({ id: firstDestination.id })]),
      );
      expect(getDestinations(GROUP2_PATH)).toHaveLength(originalDestinationsLengthForGroup2);
    });

    it('does not throw on non-existing fullPath', () => {
      expect(() =>
        removeAuditEventsStreamingDestination({
          store: cache,
          fullPath: GROUP_NOT_IN_CACHE,
          destinationId: 'fake-id',
        }),
      ).not.toThrow();
    });
  });

  describe('addAuditEventStreamingHeader', () => {
    const newHeader = destinationHeaderCreateMutationPopulator().data
      .auditEventsStreamingHeadersCreate.header;

    it('adds new header to destination', () => {
      const [firstDestination] = getDestinations(GROUP1_PATH);
      const originalLength = firstDestination.headers.nodes.length;

      addAuditEventStreamingHeader({
        store: cache,
        destinationId: firstDestination.id,
        newHeader,
      });

      const [firstDestinationAfterCreate] = getDestinations(GROUP1_PATH);
      expect(firstDestinationAfterCreate.headers.nodes).toHaveLength(originalLength + 1);
      expect(firstDestinationAfterCreate.headers.nodes).toStrictEqual(
        expect.arrayContaining([expect.objectContaining({ id: newHeader.id })]),
      );
    });

    it('does not throw on non-existing destination', () => {
      expect(() =>
        addAuditEventStreamingHeader({
          store: cache,
          destinationId: 'non-existing-id',
          newHeader,
        }),
      ).not.toThrow();
    });
  });

  describe('removeAuditEventStreamingHeader', () => {
    it('removes new header from destination', () => {
      const [, secondDestination] = getDestinations(GROUP1_PATH);
      const [firstHeader, ...restHeaders] = secondDestination.headers.nodes;

      removeAuditEventStreamingHeader({
        store: cache,
        destinationId: secondDestination.id,
        headerId: firstHeader.id,
      });

      const [, secondDestinationAfterRemove] = getDestinations(GROUP1_PATH);
      expect(secondDestinationAfterRemove.headers.nodes).toHaveLength(restHeaders.length);
      expect(secondDestinationAfterRemove.headers.nodes).not.toStrictEqual(
        expect.arrayContaining([expect.objectContaining({ id: firstHeader.id })]),
      );
    });

    it('does not throw on non-existing destination', () => {
      expect(() =>
        removeAuditEventStreamingHeader({
          store: cache,
          destinationId: 'non-existing-id',
          headerId: 'fake-id',
        }),
      ).not.toThrow();
    });
  });

  describe('updateEventTypeFilters', () => {
    it('updates event type filters on specified destination', () => {
      const [, secondDestination] = getDestinations(GROUP1_PATH);

      const newFilters = ['new-1', 'new-2'];

      updateEventTypeFilters({
        store: cache,
        destinationId: secondDestination.id,
        filters: newFilters,
      });

      const [, secondDestinationAfterUpdate] = getDestinations(GROUP1_PATH);

      expect(secondDestinationAfterUpdate.eventTypeFilters).toStrictEqual(newFilters);
    });

    it('does not throw on non-existing destination', () => {
      expect(() =>
        updateEventTypeFilters({
          store: cache,
          destinationId: 'non-existing-id',
          filters: [],
        }),
      ).not.toThrow();
    });
  });

  describe('removeEventTypeFilters', () => {
    it('removes event type filters on specified destination', () => {
      const [firstDestination] = getDestinations(GROUP1_PATH);
      const [firstFilter, ...restFilters] = firstDestination.eventTypeFilters;

      removeEventTypeFilters({
        store: cache,
        destinationId: firstDestination.id,
        filtersToRemove: [firstFilter],
      });

      const [firstDestinationAfterUpdate] = getDestinations(GROUP1_PATH);

      expect(firstDestinationAfterUpdate.eventTypeFilters).toStrictEqual(restFilters);
    });

    it('does not throw on non-existing destination', () => {
      expect(() =>
        removeEventTypeFilters({
          store: cache,
          destinationId: 'non-existing-id',
          filtersToRemove: [],
        }),
      ).not.toThrow();
    });
  });
});
