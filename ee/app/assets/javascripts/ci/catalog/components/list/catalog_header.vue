<script>
export default {
  inject: ['pageTitle', 'pageDescription'],
};
</script>
<template>
  <div>
    <h1>{{ pageTitle }}</h1>
    <p>{{ pageDescription }}</p>
  </div>
</template>
