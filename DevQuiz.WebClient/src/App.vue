<template>
  <div class="bg-primary min-h-[100dvh] min-h-screen flex flex-col gap-4 bg-center bg-no-repeat bg-cover" :style="{ backgroundImage: `url(${bg})` }">
    <AppHeader />
    <RouterView />
  </div>
</template>

<script setup lang="ts">
import AppHeader from '@/components/AppHeader.vue'
import { RouterView } from 'vue-router'
import bg from '@/assets/background/Frame 2148.png'
</script>

<style scoped lang="scss"></style>
