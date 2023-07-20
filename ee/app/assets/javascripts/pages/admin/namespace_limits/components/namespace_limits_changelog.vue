<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import dateFormat from '~/lib/dateformat';
import { joinPaths } from '~/lib/utils/url_utility';

export default {
  components: {
    GlSprintf,
    GlLink,
  },
  props: {
    entries: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    transformedEntries() {
      return this.entries.map(({ username, value, timestamp }) => ({
        url: joinPaths(gon.gitlab_url, username),
        username,
        limit: !value ? s__('NamespaceLimits|NONE') : `${value} MiB`,
        date: dateFormat(new Date(timestamp * 1000), 'yyyy-mm-dd HH:mm:ss'), // Converting timestamp to ms
      }));
    },
  },
  i18n: {
    changelogEntry: s__(
      'NamespaceLimits|%{date} %{linkStart}%{username}%{linkEnd} changed the limit to %{limit}',
    ),
  },
};
</script>
<template>
  <div>
    <p v-if="transformedEntries.length" class="gl-mt-4 gl-mb-2 gl-font-weight-bold">
      {{ __('Changelog') }}
    </p>
    <ul v-if="transformedEntries.length" data-testid="changelog-entries">
      <li v-for="(entry, index) in transformedEntries" :key="index">
        <gl-sprintf :message="$options.i18n.changelogEntry">
          <template #link>
            <gl-link :href="entry.url">{{ entry.username }}</gl-link>
          </template>
          <template #limit>
            <strong>{{ entry.limit }}</strong>
          </template>
          <template #date>
            <code>{{ entry.date }}</code>
          </template>
        </gl-sprintf>
      </li>
    </ul>
  </div>
</template>
