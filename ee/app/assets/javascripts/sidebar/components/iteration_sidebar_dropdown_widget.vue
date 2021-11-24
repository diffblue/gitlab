<script>
import {
  GlDropdownDivider,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlIcon,
  GlLink,
} from '@gitlab/ui';
import SidebarDropdownWidget from 'ee/sidebar/components/sidebar_dropdown_widget.vue';
import IterationPeriod from 'ee/iterations/components/iteration_period.vue';
import { getIterationPeriod, groupByIterationCadences } from 'ee/iterations/utils';
import { IssuableType } from '~/issue_show/constants';
import { IssuableAttributeType } from '../constants';

export default {
  issuableAttribute: IssuableAttributeType.Iteration,
  components: {
    GlDropdownDivider,
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlIcon,
    GlLink,
    SidebarDropdownWidget,
    IterationPeriod,
  },
  props: {
    attrWorkspacePath: {
      required: true,
      type: String,
    },
    iid: {
      required: true,
      type: String,
    },
    issuableType: {
      type: String,
      required: true,
      validator(value) {
        return value === IssuableType.Issue;
      },
    },
    workspacePath: {
      required: true,
      type: String,
    },
  },
  methods: {
    getCadenceTitle(currentIteration) {
      return currentIteration?.iterationCadence?.title;
    },
    getIterationPeriod(iteration) {
      return getIterationPeriod({ startDate: iteration?.startDate, dueDate: iteration?.dueDate });
    },
    groupByIterationCadences(iterations) {
      return groupByIterationCadences(iterations);
    },
  },
};
</script>

<template>
  <sidebar-dropdown-widget
    :attr-workspace-path="attrWorkspacePath"
    :iid="iid"
    :issuable-attribute="$options.issuableAttribute"
    :issuable-type="issuableType"
    :workspace-path="workspacePath"
  >
    <template #value="{ attributeTitle, attributeUrl, currentAttribute }">
      <p class="gl-font-weight-bold gl-line-height-20 gl-m-0">
        {{ getCadenceTitle(currentAttribute) }}
      </p>
      <gl-link
        class="gl-text-gray-900! gl-line-height-20"
        :href="attributeUrl"
        data-qa-selector="iteration_link"
      >
        <div>
          <gl-icon name="iteration" class="gl-mr-1" />
          {{ attributeTitle }}
        </div>
        <IterationPeriod>{{ getIterationPeriod(currentAttribute) }}</IterationPeriod>
      </gl-link>
    </template>
    <template #list="{ attributesList = [], isAttributeChecked, updateAttribute }">
      <template v-for="(cadence, index) in groupByIterationCadences(attributesList)">
        <gl-dropdown-divider v-if="index !== 0" :key="index" />
        <gl-dropdown-section-header :key="cadence.title">
          {{ cadence.title }}
        </gl-dropdown-section-header>
        <gl-dropdown-item
          v-for="iteration in cadence.iterations"
          :key="iteration.id"
          :is-check-item="true"
          :is-checked="isAttributeChecked(iteration.id)"
          :data-testid="`${$options.issuableAttribute}-items`"
          @click="updateAttribute(iteration.id)"
        >
          {{ iteration.title }}
          <IterationPeriod>{{ iteration.period }}</IterationPeriod>
        </gl-dropdown-item>
      </template>
    </template>
  </sidebar-dropdown-widget>
</template>
