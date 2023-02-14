<script>
import {
  GlDropdownDivider,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlIcon,
  GlLink,
} from '@gitlab/ui';
import IterationTitle from 'ee/iterations/components/iteration_title.vue';
import { getIterationPeriod, groupByIterationCadences } from 'ee/iterations/utils';
import { TYPE_ISSUE } from '~/issues/constants';
import { IssuableAttributeType } from '../../constants';
import SidebarDropdownWidget from '../sidebar_dropdown_widget.vue';

export default {
  issuableAttribute: IssuableAttributeType.Iteration,
  components: {
    GlDropdownDivider,
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlIcon,
    GlLink,
    SidebarDropdownWidget,
    IterationTitle,
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
        return value === TYPE_ISSUE;
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
    groupByIterationCadences,
    getIterationPeriod,
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
    <template #value="{ attributeUrl, currentAttribute }">
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
          {{ getIterationPeriod(currentAttribute) }}
        </div>
        <iteration-title v-if="currentAttribute.title" :title="currentAttribute.title" />
      </gl-link>
    </template>
    <template #list="{ attributesList = [], isAttributeChecked, updateAttribute }">
      <template v-for="(cadence, index) in groupByIterationCadences(attributesList)">
        <gl-dropdown-divider v-if="index !== 0" :key="index" />
        <gl-dropdown-section-header :key="cadence.title" data-testid="cadence-title">
          {{ cadence.title }}
        </gl-dropdown-section-header>
        <gl-dropdown-item
          v-for="iteration in cadence.iterations"
          :key="iteration.id"
          is-check-item
          :is-checked="isAttributeChecked(iteration.id)"
          :data-testid="`${$options.issuableAttribute}-items`"
          @click="updateAttribute(iteration)"
        >
          {{ iteration.period }}
          <iteration-title v-if="iteration.title" :title="iteration.title" />
        </gl-dropdown-item>
      </template>
    </template>
  </sidebar-dropdown-widget>
</template>
