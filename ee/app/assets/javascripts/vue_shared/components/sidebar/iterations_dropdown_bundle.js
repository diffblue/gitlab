import Vue from 'vue';
import VueApollo from 'vue-apollo';
import IterationDropdown from 'ee/sidebar/components/iteration_dropdown.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import createDefaultClient from '~/lib/graphql';

Vue.use(VueApollo);

export default function initIterationsDropdownBundle() {
  const el = document.querySelector('#js-iteration-dropdown');
  const iterationField = document.getElementById('issue_iteration_id');

  if (!el || !iterationField) {
    return false;
  }

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const { fullPath } = el.dataset;

  return new Vue({
    el,
    name: 'IterationDropdownRoot',
    apolloProvider,
    methods: {
      getIdForIteration(iteration) {
        const noChangeIterationValue = '';
        const unSetIterationValue = '0';

        if (iteration === null) {
          return noChangeIterationValue;
        } else if (iteration.id === null) {
          return unSetIterationValue;
        }

        return getIdFromGraphQLId(iteration.id);
      },
      handleIterationSelect(iteration) {
        iterationField.setAttribute('value', this.getIdForIteration(iteration));
      },
    },
    render(createElement) {
      return createElement(IterationDropdown, {
        props: {
          fullPath,
        },
        on: {
          onIterationSelect: this.handleIterationSelect.bind(this),
        },
      });
    },
  });
}
