import * as Sentry from '@sentry/browser';
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
import {
  SCANNER_PROFILES_QUERY,
  SITE_PROFILES_QUERY,
  ERROR_FETCH_SCANNER_PROFILES,
  ERROR_FETCH_SITE_PROFILES,
  ERROR_MESSAGES,
} from 'ee/on_demand_scans_form/settings';
import { SCANNER_TYPE, DRAWER_VIEW_MODE } from 'ee/on_demand_scans/constants';

const createProfilesApolloOptions = (name, field, savedField, { fetchQuery, fetchError }) => ({
  query: fetchQuery,
  variables() {
    return {
      fullPath: this.fullPath,
    };
  },
  update(data) {
    const nodes = data?.project?.[name]?.nodes ?? [];
    if (nodes.length === 1) {
      this[field] = nodes[0].id;
    }

    if (this[savedField] && nodes.length > 1) {
      this[field] = this.findSavedProfileId(nodes, this[savedField]);
    }

    return nodes;
  },
  error(e) {
    Sentry.captureException(e);
    this.$emit('error', ERROR_MESSAGES[fetchError]);
    this.errorType = fetchError;
  },
});
export default () => ({
  apollo: {
    sharedData: {
      query: getSharedStateQuery,
    },
    scannerProfiles: createProfilesApolloOptions(
      'scannerProfiles',
      'selectedScannerProfileId',
      'savedScannerProfileName',
      SCANNER_PROFILES_QUERY,
    ),
    siteProfiles: createProfilesApolloOptions(
      'siteProfiles',
      'selectedSiteProfileId',
      'savedSiteProfileName',
      SITE_PROFILES_QUERY,
    ),
  },
  props: {
    savedProfiles: {
      type: Object,
      required: false,
      default: null,
    },
    savedScannerProfileName: {
      type: String,
      required: false,
      default: null,
    },
    savedSiteProfileName: {
      type: String,
      required: false,
      default: null,
    },
    fullPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      sharedData: {},
      isSideDrawerOpen: false,
      scannerProfiles: [],
      siteProfiles: [],
      errorType: null,
      selectedScannerProfileId: this.savedProfiles?.dastScannerProfile.id || null,
      selectedSiteProfileId: this.savedProfiles?.dastSiteProfile.id || null,
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
    failedToLoadProfiles() {
      return [ERROR_FETCH_SCANNER_PROFILES, ERROR_FETCH_SITE_PROFILES].includes(this.errorType);
    },
    isLoadingProfiles() {
      return ['scannerProfiles', 'siteProfiles'].some((name) => this.$apollo.queries[name].loading);
    },
    isScannerProfile() {
      return this.profileType === SCANNER_TYPE;
    },
    selectedScannerProfile() {
      return this.selectedScannerProfileId
        ? this.scannerProfiles.find(({ id }) => id === this.selectedScannerProfileId)
        : null;
    },
    selectedSiteProfile() {
      return this.selectedSiteProfileId
        ? this.siteProfiles.find(({ id }) => id === this.selectedSiteProfileId)
        : null;
    },
    selectedProfiles() {
      return this.isScannerProfile ? this.scannerProfiles : this.siteProfiles;
    },
    savedScannerProfileId() {
      return this.savedScannerProfileName
        ? this.findSavedProfileId(this.scannerProfiles, this.savedScannerProfileName)
        : this.savedProfiles?.dastScannerProfile.id;
    },
    savedSiteProfileId() {
      return this.savedSiteProfileName
        ? this.findSavedProfileId(this.siteProfiles, this.savedSiteProfileName)
        : this.savedProfiles?.dastSiteProfile.id;
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
    async openProfileDrawer({ profileType, mode }) {
      if (this.sharedData.formTouched) {
        this.toggleModal({ showModal: true });
        await this.setCachedPayload({ profileType, mode });

        return;
      }

      await this.goFirstStep({ profileType, mode });

      this.isSideDrawerOpen = false;
      this.$nextTick(() => {
        this.isSideDrawerOpen = true;
        this.$emit('open-drawer');
      });
    },
    findSavedProfileId(profiles, name) {
      return profiles.find(({ profileName }) => name === profileName)?.id || null;
    },
    closeProfileDrawer() {
      this.isSideDrawerOpen = false;
      this.activeProfile = {};
    },
    reopenProfileDrawer() {
      this.isSideDrawerOpen = false;
      this.$nextTick(() => {
        this.isSideDrawerOpen = true;
      });
    },
    async selectProfile(payload) {
      this.updateProfileFromSelector(payload);
      await this.goBack();

      this.closeProfileDrawer();
    },
    isNewProfile(id) {
      return this.selectedProfiles.every((profile) => profile.id !== id);
    },
    updateProfileFromSelector({ profile: { id }, profileType }) {
      if (profileType === SCANNER_TYPE) {
        this.selectedScannerProfileId = id;
      } else {
        this.selectedSiteProfileId = id;
      }
      this.closeProfileDrawer();
    },
    onScannerProfileCreated({ profile, profileType }) {
      /**
       * TODO remove refetch method
       * after feature is complete
       * substitute with cache update flow
       */
      if (this.isNewProfile(profile.id)) {
        this.updateProfileFromSelector({ profile, profileType });
      }

      const type = `${profileType}Profiles`;
      this.$apollo.queries[type].refetch();
    },
  },
});
