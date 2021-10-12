<script>
import { GlDrawer } from '@gitlab/ui';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { COMPLIANCE_DRAWER_CONTAINER_CLASS } from '../constants';
import { getContentWrapperHeight } from '../../threat_monitoring/utils';
import BranchPath from './drawer_sections/branch_path.vue';
import Committers from './drawer_sections/committers.vue';
import MergedBy from './drawer_sections/merged_by.vue';
import Project from './drawer_sections/project.vue';
import Reference from './drawer_sections/reference.vue';
import Reviewers from './drawer_sections/reviewers.vue';

export default {
  components: {
    BranchPath,
    Committers,
    GlDrawer,
    MergedBy,
    Reference,
    Reviewers,
    Project,
  },
  props: {
    mergeRequest: {
      type: Object,
      required: true,
    },
    showDrawer: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    hasBranchDetails() {
      return this.mergeRequest.source_branch && this.mergeRequest.target_branch;
    },
    drawerHeaderHeight() {
      return getContentWrapperHeight(COMPLIANCE_DRAWER_CONTAINER_CLASS);
    },
  },
  DRAWER_Z_INDEX,
};
</script>
<template>
  <gl-drawer
    :open="showDrawer"
    :header-height="drawerHeaderHeight"
    :z-index="$options.DRAWER_Z_INDEX"
    @close="$emit('close')"
  >
    <template #title>
      <h4 data-testid="dashboard-drawer-title">{{ mergeRequest.title }}</h4>
    </template>
    <template v-if="showDrawer" #default>
      <project
        :avatar-url="mergeRequest.project.avatar_url"
        :compliance-framework="mergeRequest.compliance_management_framework"
        :name="mergeRequest.project.name"
        :url="mergeRequest.project.web_url"
      />
      <reference :path="mergeRequest.path" :reference="mergeRequest.reference" />
      <branch-path
        v-if="hasBranchDetails"
        :source-branch="mergeRequest.source_branch"
        :source-branch-uri="mergeRequest.source_branch_uri"
        :target-branch="mergeRequest.target_branch"
        :target-branch-uri="mergeRequest.target_branch_uri"
      />
      <committers :committers="mergeRequest.committers" />
      <reviewers
        :approvers="mergeRequest.approved_by_users"
        :commenters="mergeRequest.participants"
      />
      <merged-by :merged-by="mergeRequest.merged_by" />
    </template>
  </gl-drawer>
</template>
