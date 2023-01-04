import getSharedStateQuery from '../client/queries/shared_drawer_state.query.graphql';

export default {
  Mutation: {
    discardChanges(_, __, { cache }) {
      cache.updateQuery({ query: getSharedStateQuery }, ({ sharedData }) => ({
        sharedData: {
          ...sharedData,
          showDiscardChangesModal: false,
          formTouched: false,
        },
      }));
    },
    goFirstStep(_, { profileType, mode }, { cache }) {
      cache.updateQuery({ query: getSharedStateQuery }, ({ sharedData }) => ({
        sharedData: {
          ...sharedData,
          history: [{ profileType, mode }],
        },
      }));
    },
    goForward(_, { profileType, mode }, { cache }) {
      cache.updateQuery({ query: getSharedStateQuery }, ({ sharedData }) => ({
        sharedData: {
          ...sharedData,
          history: [...sharedData.history, { profileType, mode }],
        },
      }));
    },
    goBack(_, __, { cache }) {
      cache.updateQuery({ query: getSharedStateQuery }, ({ sharedData }) => ({
        sharedData: {
          ...sharedData,
          history: sharedData.history.slice(0, -1),
        },
      }));
    },
    resetHistory(_, __, { cache }) {
      cache.updateQuery({ query: getSharedStateQuery }, ({ sharedData }) => ({
        sharedData: {
          ...sharedData,
          history: [],
        },
      }));
    },
    toggleModal(_, { showDiscardChangesModal }, { cache }) {
      cache.updateQuery({ query: getSharedStateQuery }, ({ sharedData }) => ({
        sharedData: {
          ...sharedData,
          showDiscardChangesModal,
        },
      }));
    },
    setCachedPayload(_, { cachedPayload = { profileType: '', mode: '' } }, { cache }) {
      cache.updateQuery({ query: getSharedStateQuery }, ({ sharedData }) => ({
        sharedData: {
          ...sharedData,
          cachedPayload,
        },
      }));
    },
    setFormTouched(_, { formTouched }, { cache }) {
      cache.updateQuery({ query: getSharedStateQuery }, ({ sharedData }) => ({
        sharedData: {
          ...sharedData,
          formTouched,
        },
      }));
    },
    setResetAndClose(_, { resetAndClose }, { cache }) {
      cache.updateQuery({ query: getSharedStateQuery }, ({ sharedData }) => ({
        sharedData: {
          ...sharedData,
          resetAndClose,
        },
      }));
    },
  },
};
