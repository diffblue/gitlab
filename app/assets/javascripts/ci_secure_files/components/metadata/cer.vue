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
      <strong>{{ s__('SecureFiles|Name') }}:</strong>
      {{ metadata.subject.CN }}
    </p>
    <p>
      <strong>{{ s__('SecureFiles|Serial') }}:</strong>
      {{ metadata.id }}
    </p>
    <p>
      <strong>{{ s__('SecureFiles|Team') }}:</strong>
      {{ metadata.subject.O }} ({{ metadata.subject.OU }})
    </p>
    <p>
      <strong>{{ s__('SecureFiles|Issuer') }}:</strong>
      {{ metadata.issuer.CN }} - {{ metadata.issuer.OU }}
    </p>
    <p>
      <strong>{{ s__('SecureFiles|Expires at') }}:</strong>
      {{ metadata.expires_at }}
    </p>
  </div>
</template>
