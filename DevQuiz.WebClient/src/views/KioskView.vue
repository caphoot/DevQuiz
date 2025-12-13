<template>
  <div class="KioskView bg-transparent text-white p-8">
    <div class="flex gap-8 items-start">
      <div class="flex-1 min-w-0 flex flex-col gap-6">
        <div v-for="diff in selectedDifficulties" :key="diff" class="w-full max-w-4xl mx-auto">
          <LeaderboardDisplay
            :title="`${diff} Quiz`"
            :quiz-name="diff.toLowerCase()"
            class="w-full"
            :leaderboard="leaderboardStore.getLeaderboardData(diff)"
            :format-time="formatTime"
          />
        </div>
      </div>

      <div class="w-[640px] flex-shrink-0 flex flex-col gap-6 pr-8">
        <div class="bg-secondary rounded-2xl p-10 flex flex-col items-center justify-center">
          <h2 class="text-3xl font-bold mb-6">Join the Quiz!</h2>

          <div class="bg-white p-6 rounded-lg mb-6 w-full flex justify-center">
            <canvas ref="qrCanvas"></canvas>
          </div>

          <div class="text-center">
            <p class="text-xl font-mono mb-2">{{ quizUrl }}</p>
            <p class="text-white/70 text-lg">Scan or visit to start</p>
          </div>
        </div>

        <div class="bg-secondary rounded-2xl p-8">
          <OngoingParticipants :participants="activeParticipants" />
        </div>
      </div>
    </div>

    <CompletionAnimations ref="completionAnimations" />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useLeaderboardStore } from '@/stores/leaderboard'
import { useOngoingParticipantsStore } from '@/stores/ongoingParticipants'
import { api } from '@/lib/api'
import QRCode from 'qrcode'
import signalrService from '@/lib/signalrService'
import LeaderboardDisplay from '@/components/quiz/LeaderboardDisplay.vue'
import OngoingParticipants from '@/components/quiz/OngoingParticipants.vue'
import CompletionAnimations from '@/components/quiz/CompletionAnimations.vue'

const leaderboardStore = useLeaderboardStore()
const ongoingParticipantsStore = useOngoingParticipantsStore()

const qrCanvas = ref<HTMLCanvasElement>()
const completionAnimations = ref<InstanceType<typeof CompletionAnimations>>()

const quizUrl = window.location.origin

const selectedDifficulties = leaderboardStore.selectedDifficulties

const activeParticipants = computed(() => ongoingParticipantsStore.activeParticipants)

let cleanupInterval: ReturnType<typeof setInterval>
let pollInterval: ReturnType<typeof setInterval>
let signalrCleanupFunctions: (() => void)[] = []

onMounted(async () => {
  generateQRCode()

  await loadLeaderboards()
  await loadOngoingParticipants()

  await signalrService.startConnection()

  signalrCleanupFunctions.push(
    signalrService.onLeaderboardUpdate((difficulty, entries) => {
      console.log('[SignalR] Leaderboard update received:', difficulty, entries.length, 'entries')
      leaderboardStore.updateLeaderboard(difficulty, entries)
    })
  )

  signalrCleanupFunctions.push(
    signalrService.onParticipantStarted((participant) => {
      console.log('[SignalR] Participant started:', participant.name)
      ongoingParticipantsStore.addParticipant(participant)
    })
  )

  signalrCleanupFunctions.push(
    signalrService.onParticipantProgress((participant) => {
      console.log('[SignalR] Participant progress:', participant.name, 'Q', participant.currentQuestionIndex + 1)
      ongoingParticipantsStore.updateParticipant(participant)
    })
  )

  signalrCleanupFunctions.push(
    signalrService.onParticipantCompleted((completion) => {
      console.log('[SignalR] Participant completed:', completion.name, 'Rank', completion.ranking)
      ongoingParticipantsStore.removeParticipant(completion.sessionId)
      completionAnimations.value?.handleCompletion(completion)
    })
  )

  cleanupInterval = setInterval(() => {
    ongoingParticipantsStore.cleanupInactive()
  }, 5000)

  pollInterval = setInterval(async () => {
    await loadLeaderboards()
    await loadOngoingParticipants()
  }, 10000)
})

onUnmounted(async () => {
  clearInterval(cleanupInterval)
  clearInterval(pollInterval)

  signalrCleanupFunctions.forEach(cleanup => cleanup())
  signalrCleanupFunctions = []

  await signalrService.stopConnection()
})

const formatTime = (ms: number) => {
  const seconds = ms / 1000
  return `${seconds.toFixed(1)}s`
}

const loadOngoingParticipants = async () => {
  try {
    const diffs = (selectedDifficulties && selectedDifficulties.length) ? selectedDifficulties : ['Christmas']
    const results = await Promise.all(diffs.map((d: string) => api.getOngoingParticipants(d).catch(err => { console.error('ongoing fetch failed for', d, err); return [] })))

    const combined: any[] = []
    const seen = new Set<string>()
    for (const arr of results) {
      for (const p of arr) {
        if (!seen.has(p.sessionId)) {
          seen.add(p.sessionId)
          combined.push(p)
        }
      }
    }

    ongoingParticipantsStore.clearAll()
    combined.forEach(participant => ongoingParticipantsStore.addParticipant(participant))
  } catch (error) {
    console.error('Failed to load ongoing participants:', error)
  }
}

const loadLeaderboards = async () => {
  try {
    await leaderboardStore.fetchLeaderboards()
  } catch {
  }
}

const generateQRCode = async () => {
  if (qrCanvas.value) {
    try {
      await QRCode.toCanvas(qrCanvas.value, quizUrl, {
        width: 500,
        margin: 2,
        color: {
          dark: '#1e3a8a',
          light: '#ffffff',
        },
      })
    } catch {
    }
  }
}
</script>

<style scoped lang="scss">
.KioskView {
  min-width: 1400px;
  user-select: none;
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
}
</style>