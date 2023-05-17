import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import { createAlert } from '~/alert';

export default {
  data() {
    return {
      isDescriptionVersionExpanded: false,
      noteDeleted: false,
    };
  },
  computed: {
    systemNoteDescriptionVersion() {
      return this.note.systemNoteMetadata.descriptionVersion;
    },
    descriptionVersionDiffPath() {
      return this.systemNoteDescriptionVersion?.diffPath;
    },
    descriptionVersionDeletePath() {
      return this.systemNoteDescriptionVersion?.deletePath;
    },
    descriptionVersionStartId() {
      return getIdFromGraphQLId(this.systemNoteDescriptionVersion?.startVersionId);
    },
    isDescriptionVersionDeleted() {
      return this.systemNoteDescriptionVersion?.deleted;
    },
    canDeleteDescriptionVersion() {
      return this.systemNoteDescriptionVersion?.canDelete;
    },
    canSeeDescriptionVersion() {
      return Boolean(
        this.descriptionVersionDiffPath &&
          this.descriptionVersionId &&
          !this.isDescriptionVersionDeleted,
      );
    },
    displayDeleteButton() {
      return (
        this.canDeleteDescriptionVersion && !this.noteDeleted && !this.isDescriptionVersionDeleted
      );
    },
    shouldShowDescriptionVersion() {
      return this.canSeeDescriptionVersion && this.isDescriptionVersionExpanded;
    },
    descriptionVersionToggleIcon() {
      return this.isDescriptionVersionExpanded ? 'chevron-up' : 'chevron-down';
    },
  },
  methods: {
    async fetchDescriptionVersion({ endpoint, startingVersion, versionId }) {
      let requestUrl = endpoint;

      if (startingVersion) {
        requestUrl = mergeUrlParams({ start_version_id: startingVersion }, requestUrl);
      }

      this.isLoadingDescriptionVersion = true;

      await axios
        .get(requestUrl)
        .then((res) => {
          this.isLoadingDescriptionVersion = false;
          // need to use Vue.set to make sure the object key is reactive
          // https://v2.vuejs.org/v2/api/#Vue-set
          this.$set(this.descriptionVersions, versionId, res.data);
        })
        .catch(() => {
          createAlert({
            message: __(
              'Something went wrong while fetching description changes. Please try again.',
            ),
          });
        })
        .finally(() => {
          this.isLoadingDescriptionVersion = false;
        });
    },
    async softDeleteDescriptionVersion({ endpoint, startVersion, versionId }) {
      let requestUrl = endpoint;

      if (startVersion) {
        requestUrl = mergeUrlParams({ start_version_id: startVersion }, requestUrl);
      }

      await axios
        .delete(requestUrl)
        .then(() => {
          this.noteDeleted = true;
          // no need to use vue.set the next time , first time ensures that it is reactive
          this.descriptionVersions[versionId] = '<span>Deleted</span>';
        })
        .catch((error) => {
          createAlert({
            message: __(
              'Something went wrong while deleting description changes. Please try again.',
            ),
          });
          throw new Error(error);
        });
    },
    toggleDescriptionVersion() {
      this.isDescriptionVersionExpanded = !this.isDescriptionVersionExpanded;

      const versionId = this.descriptionVersionId;

      if (this.descriptionVersions?.[versionId]) {
        return false;
      }

      const startingVersion = this.descriptionVersionStartId;

      return this.fetchDescriptionVersion({
        endpoint: this.descriptionVersionDiffPath,
        startingVersion,
        versionId,
      });
    },
    deleteDescriptionVersion() {
      return this.softDeleteDescriptionVersion({
        endpoint: this.descriptionVersionDeletePath,
        startVersion: this.descriptionVersionStartId,
        versionId: this.descriptionVersionId,
      }).catch(() => {
        this.noteDeleted = false;
      });
    },
  },
};
