import Vue from 'vue';

import HealthStatusSelect from 'ee/sidebar/components/status/health_status_dropdown.vue';

import { healthStatusForRestApi } from 'ee/sidebar/constants';

export default () => {
  const el = document.getElementById('js-bulk-update-health-status-root');
  const healthStatusFormFieldEl = document.getElementById('issue_health_status_value');

  if (!el && !healthStatusFormFieldEl) {
    return false;
  }

  return new Vue({
    el,
    name: 'HealthStatusSelectRoot',
    components: {
      HealthStatusSelect,
    },
    data() {
      return {
        selectedStatus: undefined,
      };
    },
    methods: {
      handleHealthStatusSelect(selectedStatus) {
        this.selectedStatus = selectedStatus;
        healthStatusFormFieldEl.setAttribute(
          'value',
          healthStatusForRestApi[selectedStatus || 'NO_STATUS'],
        );
      },
    },
    render(createElement) {
      return createElement('health-status-select', {
        props: {
          isFetching: false,
          isEditable: true,
          showDropdown: true,
          status: this.selectedStatus,
        },
        on: {
          onDropdownClick: this.handleHealthStatusSelect.bind(this),
        },
      });
    },
  });
};
