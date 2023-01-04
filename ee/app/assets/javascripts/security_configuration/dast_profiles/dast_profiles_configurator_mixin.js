import { SCANNER_TYPE, DRAWER_VIEW_MODE } from 'ee/on_demand_scans/constants';
import getSharedStateQuery from 'ee/vue_shared/security_configuration/graphql/client/queries/shared_drawer_state.query.graphql';
import goFirstStepMutation from 'ee/vue_shared/security_configuration/graphql/client/mutations/go_first_history_step.mutation.graphql';
import goForwardMutation from 'ee/vue_shared/security_configuration/graphql/client/mutations/go_forward_history.mutation.graphql';
import discardMutationsMutation from 'ee/vue_shared/security_configuration/graphql/client/mutations/discard_changes.mutation.graphql';
import toggleModalMutation from 'ee/vue_shared/security_configuration/graphql/client/mutations/toggle_modal.mutation.graphql';
import resetHistoryMutation from 'ee/vue_shared/security_configuration/graphql/client/mutations/reset_history.mutation.graphql';
import setFormTouchedMutation from 'ee/vue_shared/security_configuration/graphql/client/mutations/set_form_touched.mutation.graphql';
import setResetAndClose from 'ee/vue_shared/security_configuration/graphql/client/mutations/set_reset_and_close.mutation.graphql';
import setCachedPayloadMutation from 'ee/vue_shared/security_configuration/graphql/client/mutations/set_cached_payload.mutation.graphql';
import goBackMutation from 'ee/vue_shared/security_configuration/graphql/client/mutations/go_back_history.mutation.graphql';

export default () => ({
  apollo: {
    sharedData: {
      query: getSharedStateQuery,
    },
  },
  data() {
    return {
      sharedData: {},
    };
  },
  computed: {
    hasCachedPayload() {
      return Boolean(this.sharedData.cachedPayload?.profileType);
    },
    cachedPayload() {
      return this.sharedData.cachedPayload;
    },
    lastHistoryIndex() {
      return (this.sharedData.history?.length || 0) > 0 ? this.sharedData.history.length - 1 : 0;
    },
    profileType() {
      return this.sharedData.history?.[this.lastHistoryIndex]?.profileType || SCANNER_TYPE;
    },
    drawerViewMode() {
      return (
        this.sharedData.history?.[this.lastHistoryIndex]?.mode || DRAWER_VIEW_MODE.READING_MODE
      );
    },
    eventName() {
      return (this.sharedData.history?.length || 0) > 0 ? 'reopen-drawer' : 'close-drawer';
    },
  },
  methods: {
    goFirstStep({ profileType, mode }) {
      return this.$apollo.mutate({
        mutation: goFirstStepMutation,
        variables: { profileType, mode },
      });
    },
    goForward({ profileType, mode }) {
      return this.$apollo.mutate({
        mutation: goForwardMutation,
        variables: { profileType, mode },
      });
    },
    goBack() {
      return this.$apollo.mutate({
        mutation: goBackMutation,
      });
    },
    toggleModal({ showModal }) {
      return this.$apollo.mutate({
        mutation: toggleModalMutation,
        variables: { showDiscardChangesModal: showModal },
      });
    },
    discardChanges() {
      return this.$apollo.mutate({
        mutation: discardMutationsMutation,
      });
    },
    setFormTouched({ isTouched }) {
      return this.$apollo.mutate({
        mutation: setFormTouchedMutation,
        variables: { formTouched: isTouched },
      });
    },
    resetHistory() {
      return this.$apollo.mutate({
        mutation: resetHistoryMutation,
      });
    },
    setCachedPayload({ profileType, mode } = { profileType: '', mode: '' }) {
      return this.$apollo.mutate({
        mutation: setCachedPayloadMutation,
        variables: { cachedPayload: { profileType, mode } },
      });
    },
    setResetAndClose({ resetAndClose }) {
      return this.$apollo.mutate({
        mutation: setResetAndClose,
        variables: { resetAndClose },
      });
    },
  },
});
