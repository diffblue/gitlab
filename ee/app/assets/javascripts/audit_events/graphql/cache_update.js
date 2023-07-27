import produce from 'immer';
import getExternalDestinationsQuery from './queries/get_external_destinations.query.graphql';
import getInstanceExternalDestinationsQuery from './queries/get_instance_external_destinations.query.graphql';
import gcpLoggingDestinationsQuery from './queries/get_get_google_cloud_logging_destinations.query.graphql';
import ExternalAuditEventDestinationFragment from './fragments/external_audit_event_destination.fragment.graphql';
import InstanceExternalAuditEventDestinationFragment from './fragments/instance_external_audit_event_destination.fragment.graphql';

const EXTERNAL_AUDIT_EVENT_DESTINATION_TYPENAME = 'ExternalAuditEventDestination';
const INSTANCE_EXTERNAL_AUDIT_EVENT_DESTINATION_TYPENAME = 'InstanceExternalAuditEventDestination';

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

function makeInstanceDestinationIdRecord(store, id) {
  return {
    id: store.identify({
      __typename: INSTANCE_EXTERNAL_AUDIT_EVENT_DESTINATION_TYPENAME,
      id,
    }),
    fragment: InstanceExternalAuditEventDestinationFragment,
    fragmentName: 'InstanceExternalAuditEventDestinationFragment',
  };
}

export function addAuditEventsStreamingDestination({ store, fullPath, newDestination }) {
  const getDestinationQuery =
    fullPath === 'instance' ? getInstanceExternalDestinationsQuery : getExternalDestinationsQuery;

  const sourceData = store.readQuery({
    query: getDestinationQuery,
    variables: { fullPath },
  });

  if (!sourceData) {
    return;
  }

  const data = produce(sourceData, (draftData) => {
    const nodes =
      fullPath === 'instance'
        ? draftData.instanceExternalAuditEventDestinations.nodes
        : draftData.group.externalAuditEventDestinations.nodes;
    nodes.unshift(newDestination);
  });

  store.writeQuery({ query: getDestinationQuery, variables: { fullPath }, data });
}

export function removeAuditEventsStreamingDestination({ store, fullPath, destinationId }) {
  const getDestinationQuery =
    fullPath === 'instance' ? getInstanceExternalDestinationsQuery : getExternalDestinationsQuery;
  const sourceData = store.readQuery({
    query: getDestinationQuery,
    variables: { fullPath },
  });

  if (!sourceData) {
    return;
  }

  const data = produce(sourceData, (draftData) => {
    if (fullPath === 'instance') {
      draftData.instanceExternalAuditEventDestinations.nodes = draftData.instanceExternalAuditEventDestinations.nodes.filter(
        (node) => node.id !== destinationId,
      );
    } else {
      draftData.group.externalAuditEventDestinations.nodes = draftData.group.externalAuditEventDestinations.nodes.filter(
        (node) => node.id !== destinationId,
      );
    }
  });
  store.writeQuery({ query: getDestinationQuery, variables: { fullPath }, data });
}

export function addAuditEventStreamingHeader({ store, fullPath, destinationId, newHeader }) {
  const destinationIdRecord =
    fullPath === 'instance'
      ? makeInstanceDestinationIdRecord(store, destinationId)
      : makeDestinationIdRecord(store, destinationId);
  const sourceDestination = store.readFragment(destinationIdRecord);
  if (!sourceDestination) {
    return;
  }

  const destination = produce(sourceDestination, (draftDestination) => {
    draftDestination.headers.nodes.push(newHeader);
  });
  store.writeFragment({ ...destinationIdRecord, data: destination });
}

export function removeAuditEventStreamingHeader({ store, fullPath, destinationId, headerId }) {
  const destinationIdRecord =
    fullPath === 'instance'
      ? makeInstanceDestinationIdRecord(store, destinationId)
      : makeDestinationIdRecord(store, destinationId);
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

export function updateEventTypeFilters({ store, isInstance, destinationId, filters }) {
  const destinationIdRecord = isInstance
    ? makeInstanceDestinationIdRecord(store, destinationId)
    : makeDestinationIdRecord(store, destinationId);

  const sourceDestination = store.readFragment(destinationIdRecord);

  if (!sourceDestination) {
    return;
  }

  const destination = produce(sourceDestination, (draftDestination) => {
    draftDestination.eventTypeFilters = filters;
  });
  store.writeFragment({ ...destinationIdRecord, data: destination });
}

export function removeEventTypeFilters({ store, isInstance, destinationId, filtersToRemove = [] }) {
  const destinationIdRecord = isInstance
    ? makeInstanceDestinationIdRecord(store, destinationId)
    : makeDestinationIdRecord(store, destinationId);

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

export function addGcpLoggingAuditEventsStreamingDestination({ store, fullPath, newDestination }) {
  const sourceData = store.readQuery({
    query: gcpLoggingDestinationsQuery,
    variables: { fullPath },
  });

  if (!sourceData) {
    return;
  }

  const data = produce(sourceData, (draftData) => {
    const { nodes } = draftData.group.googleCloudLoggingConfigurations;
    nodes.unshift(newDestination);
  });

  store.writeQuery({ query: gcpLoggingDestinationsQuery, variables: { fullPath }, data });
}

export function removeGcpLoggingAuditEventsStreamingDestination({
  store,
  fullPath,
  destinationId,
}) {
  const sourceData = store.readQuery({
    query: gcpLoggingDestinationsQuery,
    variables: { fullPath },
  });

  if (!sourceData) {
    return;
  }

  const data = produce(sourceData, (draftData) => {
    draftData.group.googleCloudLoggingConfigurations.nodes = draftData.group.googleCloudLoggingConfigurations.nodes.filter(
      (node) => node.id !== destinationId,
    );
  });

  store.writeQuery({ query: gcpLoggingDestinationsQuery, variables: { fullPath }, data });
}
