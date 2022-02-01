<script>
import { GlAvatarLink, GlAvatar, GlAvatarsInline, GlTooltipDirective } from '@gitlab/ui';
import { sprintf, __, n__ } from '~/locale';
import { PRESENTABLE_APPROVERS_LIMIT } from '../../constants';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlAvatarsInline,
    GlAvatarLink,
    GlAvatar,
  },
  props: {
    approvers: {
      type: Array,
      required: true,
    },
  },
  computed: {
    hasApprovers() {
      return this.approvers.length > 0;
    },
    approversToPresent() {
      return this.approvers.slice(0, PRESENTABLE_APPROVERS_LIMIT);
    },
    amountOfApproversOverLimit() {
      return this.approvers.length - PRESENTABLE_APPROVERS_LIMIT;
    },
    isApproversOverLimit() {
      return this.amountOfApproversOverLimit > 0;
    },
    approversOverLimitString() {
      return sprintf(__('+%{approvers} more approvers'), {
        approvers: this.amountOfApproversOverLimit,
      });
    },
    approversBadgeSrOnlyText() {
      return n__(
        '%d additional approver',
        '%d additional approvers',
        this.amountOfApproversOverLimit,
      );
    },
  },
  PRESENTABLE_APPROVERS_LIMIT,
  strings: {
    approvedBy: __('approved by: '),
    noApprovers: __('no approvers'),
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center gl-justify-content-end" data-testid="approvers">
    <span class="gl-text-gray-500">
      <template v-if="hasApprovers">
        {{ $options.strings.approvedBy }}
      </template>
      <template v-else>
        {{ $options.strings.noApprovers }}
      </template>
    </span>
    <gl-avatars-inline
      v-if="hasApprovers"
      :avatars="approvers"
      :collapsed="true"
      :max-visible="$options.PRESENTABLE_APPROVERS_LIMIT"
      :avatar-size="24"
      :badge-sr-only-text="approversBadgeSrOnlyText"
      class="gl-display-inline-flex gl-lg-display-none! gl-ml-3"
      badge-tooltip-prop="name"
    >
      <template #avatar="{ avatar }">
        <gl-avatar-link
          v-gl-tooltip
          target="blank"
          :href="avatar.web_url"
          :title="avatar.name"
          class="gl-text-gray-900 author-link js-user-link"
        >
          <gl-avatar
            :src="avatar.avatar_url"
            :entity-id="avatar.id"
            :entity-name="avatar.name"
            :size="24"
          />
        </gl-avatar-link>
      </template>
    </gl-avatars-inline>

    <gl-avatar-link
      v-for="approver in approversToPresent"
      :key="approver.id"
      :title="approver.name"
      :href="approver.web_url"
      :data-user-id="approver.id"
      :data-name="approver.name"
      class="gl-display-none gl-lg-display-inline-flex! gl-align-items-center gl-justify-content-end gl-ml-3 gl-text-gray-900 author-link js-user-link"
    >
      <gl-avatar
        :src="approver.avatar_url"
        :entity-id="approver.id"
        :entity-name="approver.name"
        :size="16"
        class="gl-mr-2"
      />
      <span>{{ approver.name }}</span>
    </gl-avatar-link>
    <span
      v-if="isApproversOverLimit"
      v-gl-tooltip.top="approversOverLimitString"
      class="gl-display-none gl-lg-display-inline-block! avatar-counter gl-ml-3 gl-px-2 gl-flex-shrink-0 gl-flex-grow-0"
      >+ {{ amountOfApproversOverLimit }}</span
    >
  </div>
</template>
