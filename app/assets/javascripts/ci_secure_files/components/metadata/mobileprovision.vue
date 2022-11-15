<script>
export default {
  props: {
    metadata: {
      required: true,
      type: Object,
    },
  },
};
</script>

<template>
  <div>
    <p>
      <strong>{{ s__('SecureFiles|UUID') }}:</strong>
      {{ metadata.id }}
    </p>
    <p>
      <strong>{{ s__('SecureFiles|Platforms') }}:</strong>
      {{ metadata.platforms.join(', ') }}
    </p>
    <p>
      <strong>{{ s__('SecureFiles|Team') }}:</strong>
      {{ metadata.team_name }} ({{ metadata.team_id.join(', ') }})
    </p>
    <p>
      <strong>{{ s__('SecureFiles|App') }}:</strong>
      {{ metadata.app_name }} - {{ metadata.app_id }}
    </p>
    <p>
      <strong>{{ s__('SecureFiles|Certificates') }}:</strong>
      {{ metadata.certificate_ids.join(', ') }}
    </p>
    <p>
      <strong>{{ s__('SecureFiles|Expires at') }}:</strong>
      {{ metadata.expires_at }}
    </p>
  </div>
</template>
