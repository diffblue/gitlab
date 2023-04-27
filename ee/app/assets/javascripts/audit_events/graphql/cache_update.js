import produce from 'immer';
import getExternalDestinationsQuery from './queries/get_external_destinations.query.graphql';
import ExternalAuditEventDestinationFragment from './fragments/external_audit_event_destination.fragment.graphql';

const EXTERNAL_AUDIT_EVENT_DESTINATION_TYPENAME = 'ExternalAuditEventDestination';

function makeDestinationIdRecord(store, id) {
  return {
    id: store.identify({
      __typename: EXTERNAL_AUDIT_EVENT_DESTINATION_TYPENAME,
      id,
    }),
    fragment: ExternalAuditEventDestinationFragment,
    fragmentName: 'ExternalAuditEventDestinationFragment',
  };
}

export function addAuditEventsStreamingDestination({ store, fullPath, newDestination }) {
  const sourceData = store.readQuery({
    query: getExternalDestinationsQuery,
    variables: { fullPath },
  });

  if (!sourceData) {
    return;
  }

  const data = produce(sourceData, (draftData) => {
    draftData.group.externalAuditEventDestinations.nodes.push(newDestination);
  });
  store.writeQuery({ query: getExternalDestinationsQuery, variables: { fullPath }, data });
}

export function removeAuditEventsStreamingDestination({ store, fullPath, destinationId }) {
  const sourceData = store.readQuery({
    query: getExternalDestinationsQuery,
    variables: { fullPath },
  });

  if (!sourceData) {
    return;
  }

  const data = produce(sourceData, (draftData) => {
    draftData.group.externalAuditEventDestinations.nodes = draftData.group.externalAuditEventDestinations.nodes.filter(
      (node) => node.id !== destinationId,
    );
  });
  store.writeQuery({ query: getExternalDestinationsQuery, variables: { fullPath }, data });
}

export function addAuditEventStreamingHeader({ store, destinationId, newHeader }) {
  const destinationIdRecord = makeDestinationIdRecord(store, destinationId);
  const sourceDestination = store.readFragment(destinationIdRecord);

  if (!sourceDestination) {
    return;
  }

  const destination = produce(sourceDestination, (draftDestination) => {
    draftDestination.headers.nodes.push(newHeader);
  });
  store.writeFragment({ ...destinationIdRecord, data: destination });
}

export function removeAuditEventStreamingHeader({ store, destinationId, headerId }) {
  const destinationIdRecord = makeDestinationIdRecord(store, destinationId);
  const sourceDestination = store.readFragment(destinationIdRecord);

  if (!sourceDestination) {
    return;
  }

  const destination = produce(sourceDestination, (draftDestination) => {
    draftDestination.headers.nodes = draftDestination.headers.nodes.filter(
      ({ id }) => id !== headerId,
    );
  });
  store.writeFragment({ ...destinationIdRecord, data: destination });
}

export function updateEventTypeFilters({ store, destinationId, filters }) {
  const destinationIdRecord = makeDestinationIdRecord(store, destinationId);
  const sourceDestination = store.readFragment(destinationIdRecord);

  if (!sourceDestination) {
    return;
  }

  const destination = produce(sourceDestination, (draftDestination) => {
    draftDestination.eventTypeFilters = filters;
  });
  store.writeFragment({ ...destinationIdRecord, data: destination });
}

export function removeEventTypeFilters({ store, destinationId, filtersToRemove = [] }) {
  const destinationIdRecord = makeDestinationIdRecord(store, destinationId);
  const sourceDestination = store.readFragment(destinationIdRecord);

  if (!sourceDestination) {
    return;
  }

  const destination = produce(sourceDestination, (draftDestination) => {
    draftDestination.eventTypeFilters = draftDestination.eventTypeFilters.filter(
      (entry) => !filtersToRemove.includes(entry),
    );
  });
  store.writeFragment({ ...destinationIdRecord, data: destination });
}
