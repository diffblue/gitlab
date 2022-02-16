import Vue from 'vue';

import EpicsSelect from 'ee/vue_shared/components/sidebar/epics_select/base.vue';
import { DropdownVariant } from 'ee/vue_shared/components/sidebar/epics_select/constants';
import { placeholderEpic } from 'ee/vue_shared/constants';

export default () => {
  const el = document.getElementById('js-epic-select-root');
  const epicFormFieldEl = document.getElementById('issue_epic_id');

  if (!el && !epicFormFieldEl) {
    return false;
  }

  return new Vue({
    el,
    name: 'EpicsSelectRoot',
    components: {
      EpicsSelect,
    },
    data() {
      return {
        selectedEpic: placeholderEpic,
      };
    },
    methods: {
      handleEpicSelect(selectedEpic) {
        this.selectedEpic = selectedEpic;
        epicFormFieldEl.setAttribute('value', selectedEpic.id);
      },
    },
    render(createElement) {
      return createElement('epics-select', {
        props: {
          groupId: parseInt(el.dataset.groupId, 10),
          issueId: 0,
          epicIssueId: 0,
          canEdit: true,
          initialEpic: this.selectedEpic,
          initialEpicLoading: false,
          variant: DropdownVariant.Standalone,
          showHeader: Boolean(el.dataset.showHeader),
        },
        on: {
          epicSelect: this.handleEpicSelect.bind(this),
        },
      });
    },
  });
};
