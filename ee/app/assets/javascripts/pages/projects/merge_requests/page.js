import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { concatPagination } from '@apollo/client/utilities';
import SummaryNotes from 'ee/merge_requests/components/summary_notes.vue';
import createDefaultClient from '~/lib/graphql';

Vue.use(VueApollo);

export { initMrPage } from '~/pages/projects/merge_requests/page';

requestIdleCallback(() => {
  const summaryNotesEl = document.getElementById('js-summary-notes');

  if (summaryNotesEl) {
    const defaultClient = createDefaultClient(
      {},
      {
        cacheConfig: {
          typePolicies: {
            MergeRequest: {
              fields: {
                diffLlmSummaries: {
                  keyArgs: ['fullPath', 'iid'],
                },
              },
            },
            MergeRequestDiffLlmSummaryConnection: {
              fields: {
                nodes: concatPagination(),
              },
            },
          },
        },
      },
    );
    const apolloProvider = new VueApollo({ defaultClient });
    const { dataset } = summaryNotesEl;

    // eslint-disable-next-line no-new
    new Vue({
      el: summaryNotesEl,
      apolloProvider,
      provide: {
        iid: dataset.iid,
        projectPath: dataset.projectPath,
        emptyStateSvg: dataset.emptyStateSvg,
      },
      render(h) {
        return h(SummaryNotes);
      },
    });
  }
});
