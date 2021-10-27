<script>
import { GlButton, GlFormGroup, GlDropdown, GlDropdownItem, GlDropdownDivider } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import { __ } from '~/locale';
import { ALL_ENVIRONMENT_NAME, LOADING_TEXT } from '../constants';

export default {
  components: {
    GlButton,
    GlFormGroup,
    GlDropdown,
    GlDropdownDivider,
    GlDropdownItem,
  },
  props: {
    includeAll: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  i18n: {
    loadMore: __('Load more'),
  },
  computed: {
    ...mapState('threatMonitoring', [
      'allEnvironments',
      'currentEnvironmentId',
      'environments',
      'isLoadingEnvironments',
      'hasEnvironment',
      'nextPage',
    ]),
    ...mapGetters('threatMonitoring', ['currentEnvironmentName', 'canChangeEnvironment']),
    environmentName() {
      if (this.isDropdownInitiallyLoading) {
        return LOADING_TEXT;
      } else if (this.allEnvironments && this.includeAll) {
        return ALL_ENVIRONMENT_NAME;
      }
      return this.currentEnvironmentName;
    },
    isDropdownInitiallyLoading() {
      return this.isLoadingEnvironments && !this.environments.length;
    },
  },
  created() {
    if (this.hasEnvironment) {
      this.fetchEnvironments();
    }
  },
  methods: {
    ...mapActions('threatMonitoring', [
      'fetchEnvironments',
      'setCurrentEnvironmentId',
      'setAllEnvironments',
    ]),
    isEnvironmentChecked(currentEnvironmentName) {
      return currentEnvironmentName === this.environmentName;
    },
  },
  environmentFilterId: 'threat-monitoring-environment-filter',
  ALL_ENVIRONMENT_NAME,
};
</script>

<template>
  <gl-form-group
    :label="s__('ThreatMonitoring|Environment')"
    :label-for="$options.environmentFilterId"
  >
    <gl-dropdown
      :id="$options.environmentFilterId"
      class="gl-display-flex"
      toggle-class="gl-truncate"
      :text="environmentName"
      :disabled="!canChangeEnvironment"
      :loading="isDropdownInitiallyLoading"
    >
      <gl-dropdown-item
        v-if="includeAll"
        :is-check-item="true"
        :is-checked="allEnvironments"
        @click="setAllEnvironments"
      >
        {{ $options.ALL_ENVIRONMENT_NAME }}
      </gl-dropdown-item>
      <gl-dropdown-divider v-if="includeAll" />
      <gl-dropdown-item
        v-for="environment in environments"
        :key="environment.id"
        :is-check-item="true"
        :is-checked="isEnvironmentChecked(environment.name)"
        @click="setCurrentEnvironmentId(environment.id)"
      >
        {{ environment.name }}
      </gl-dropdown-item>
      <gl-button
        v-if="Boolean(nextPage)"
        variant="link"
        class="gl-w-full"
        :loading="isLoadingEnvironments"
        @click="fetchEnvironments"
      >
        {{ this.$options.i18n.loadMore }}
      </gl-button>
    </gl-dropdown>
  </gl-form-group>
</template>
