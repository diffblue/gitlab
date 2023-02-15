import Vue from 'vue';
import { TYPE_EPIC } from '~/issues/constants';
import { parseBoolean } from '~/lib/utils/common_utils';
import RelatedEpicsRoot from '~/related_issues/components/related_issues_root.vue';
import { PathIdSeparator } from '~/related_issues/constants';

export default function initRelatedEpics() {
  const relatedEpicsRootEl = document.querySelector('#js-related-epics');

  if (relatedEpicsRootEl) {
    const {
      endpoint,
      canAddRelatedEpics,
      helpPath,
      showCategorizedEpics,
    } = relatedEpicsRootEl.dataset;

    // eslint-disable-next-line no-new
    new Vue({
      el: relatedEpicsRootEl,
      name: 'LinkedEpicsRoot',
      components: {
        RelatedEpicsRoot,
      },
      render: (createElement) =>
        createElement('related-epics-root', {
          props: {
            endpoint,
            helpPath,
            canAdmin: parseBoolean(canAddRelatedEpics),
            showCategorizedIssues: parseBoolean(showCategorizedEpics),
            pathIdSeparator: PathIdSeparator.Epic,
            issuableType: TYPE_EPIC,
            autoCompleteIssues: false,
          },
        }),
    });
  }
}
