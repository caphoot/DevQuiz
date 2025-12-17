<template>
  <div class="FinishView flex items-start justify-center min-h-screen px-4 pt-4">
    <div class="max-w-md w-full bg-[#2b2330] rounded-xl shadow-lg p-8 text-center text-white -mt-2">
      <p class="text-lg font-semibold mb-4">Not bad! The Grinch would have turned green with envy!</p>

      <div class="text-6xl mb-4">🎉</div>

      <div class="text-sm text-gray-300 mb-2">Your total time</div>
      <div class="text-4xl font-extrabold mb-2">{{ formattedTime }}</div>

      <div class="text-yellow-400 text-sm mb-4">🏆 {{ leaderBoard?.position ?? '—' }} place of {{ leaderBoard?.totalParticipants ?? '—' }} participants</div>

      <p class="text-gray-300 text-sm mb-6">Thanks for participating! Try again next year for an even better ranking.</p>

      <button
        @click="goHome"
        class="w-full py-3 bg-[#0071AD] text-white rounded-lg font-medium hover:bg-[#005f8a] transition-colors"
      >
        Back to Home
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { api, type LeaderboardPersonalScore } from '@/lib/api'
import ContactForm from '@/components/ContactForm.vue'

const router = useRouter()
const leaderBoard = ref<LeaderboardPersonalScore | null>(null)
onMounted(async () => {
  leaderBoard.value = await api.getMyScore()
})

const formattedTime = computed(() => {
  const totalMs = leaderBoard.value?.totalMs
  if (!totalMs) return '0.0s'
  const seconds = totalMs / 1000
  return `${seconds.toFixed(1)}s`
})

const goHome = () => {
  router.push('/')
}
</script>

<style scoped lang="scss"></style>
