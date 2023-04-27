import { getTimeago } from '~/lib/utils/datetime_utility';
import { __, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

import { filterState } from '../constants';

export default {
  legacyReferenceDeprecationUrl: helpPagePath('update/deprecations', {
    anchor: 'the-gitlab-legacy-requirement-iid-is-deprecated-in-favor-of-work-item-iid',
  }),
  computed: {
    reference() {
      return `#${this.requirement?.workItemIid}`;
    },
    legacyReference() {
      return `REQ-${this.requirement?.iid}`;
    },
    titleHtml() {
      return this.requirement?.titleHtml;
    },
    descriptionHtml() {
      return this.requirement?.descriptionHtml;
    },
    isArchived() {
      return this.requirement?.state === filterState.archived;
    },
    author() {
      return this.requirement?.author;
    },
    createdAtFormatted() {
      return sprintf(__('created %{timeAgo}'), {
        timeAgo: getTimeago().format(this.requirement?.createdAt),
      });
    },
    updatedAtFormatted() {
      return sprintf(__('updated %{timeAgo}'), {
        timeAgo: getTimeago().format(this.requirement?.updatedAt),
      });
    },
    testReport() {
      return this.requirement?.testReports.nodes[0];
    },
    canUpdate() {
      return this.requirement?.userPermissions.updateRequirement;
    },
    canArchive() {
      return this.requirement?.userPermissions.adminRequirement;
    },
  },
};
