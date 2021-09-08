<script>
import { GlFormGroup, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import { ALL_ENVIRONMENT_NAME, LOADING_TEXT } from '../constants';

export default {
  components: {
    GlFormGroup,
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    includeAll: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapState('threatMonitoring', [
      'environments',
      'currentEnvironmentId',
      'allEnvironments',
      'isLoadingEnvironments',
    ]),
    ...mapGetters('threatMonitoring', ['currentEnvironmentName', 'canChangeEnvironment']),
    environmentName() {
      if (this.isLoadingEnvironments) {
        return LOADING_TEXT;
      } else if (this.allEnvironments && this.includeAll) {
        return ALL_ENVIRONMENT_NAME;
      }
      return this.currentEnvironmentName;
    },
  },
  methods: {
    ...mapActions('threatMonitoring', ['setCurrentEnvironmentId', 'setAllEnvironments']),
  },
  environmentFilterId: 'threat-monitoring-environment-filter',
  ALL_ENVIRONMENT_NAME,
};
</script>

<template>
  <gl-form-group
    :label="s__('ThreatMonitoring|Environment')"
    label-size="sm"
    :label-for="$options.environmentFilterId"
  >
    <gl-dropdown
      :id="$options.environmentFilterId"
      class="gl-display-flex"
      toggle-class="gl-truncate"
      :text="environmentName"
      :disabled="!canChangeEnvironment"
      :loading="isLoadingEnvironments"
    >
      <gl-dropdown-item
        v-for="environment in environments"
        :key="environment.id"
        @click="setCurrentEnvironmentId(environment.id)"
      >
        {{ environment.name }}
      </gl-dropdown-item>
      <gl-dropdown-item v-if="includeAll" @click="setAllEnvironments">
        {{ $options.ALL_ENVIRONMENT_NAME }}
      </gl-dropdown-item>
    </gl-dropdown>
  </gl-form-group>
</template>
