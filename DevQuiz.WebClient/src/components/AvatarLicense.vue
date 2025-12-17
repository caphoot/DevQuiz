<template>
  <footer class="avatar-license" aria-hidden="true">
    Avatars are licensed under
    <a href="https://creativecommons.org/licenses/by-sa/4.0/" target="_blank" rel="noopener noreferrer">CC BY-SA 4.0</a>
  </footer>
</template>

<script setup lang="ts">
// empty
</script>

<style scoped lang="scss">
.avatar-license {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 8px;
  text-align: center;
  font-size: 12px;
  color: rgba(255,255,255,0.75);
  z-index: 60;
}
.avatar-license a {
  color: rgba(255,255,255,0.85);
  text-decoration: underline;
}
</style>
