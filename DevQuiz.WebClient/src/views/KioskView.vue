<template>
  <div class="KioskView bg-primary text-white p-8">
    <div class="flex gap-8">
      <div class="flex flex-col gap-6">
        <!-- Render one leaderboard per selected difficulty -->
        <LeaderboardDisplay
          v-for="diff in selectedDifficulties"
          :key="diff"
          :title="`${diff} Quiz`"
          :quiz-name="diff.toLowerCase()"
          :leaderboard="leaderboardStore.getLeaderboardData(diff)"
          :format-time="formatTime"
        />
      </div>

      <!-- QR Code and Active Participants -->
      <div class="w-[600px] flex flex-col gap-6">
        <div class="bg-secondary rounded-2xl p-8 flex flex-col items-center justify-center">
          <h2 class="text-3xl font-bold mb-6">Join the Quiz!</h2>

          <div class="bg-white p-6 rounded-lg mb-6">
            <canvas ref="qrCanvas"></canvas>
          </div>

          <div class="text-center">
            <p class="text-xl font-mono mb-2">{{ quizUrl }}</p>
            <p class="text-white/70 text-lg">Scan or visit to start</p>
          </div>
        </div>

        <!-- Active Participants -->
        <div class="bg-secondary rounded-2xl p-6">
          <OngoingParticipants :participants="activeParticipants" />
        </div>
      </div>
    </div>

    <!-- Completion Animations -->
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

// Use the selected difficulties from the leaderboard store (Pinia unwraps refs on access)
const selectedDifficulties = leaderboardStore.selectedDifficulties

const activeParticipants = computed(() => ongoingParticipantsStore.activeParticipants)

let cleanupInterval: ReturnType<typeof setInterval>
let pollInterval: ReturnType<typeof setInterval>
let signalrCleanupFunctions: (() => void)[] = []

onMounted(async () => {
  generateQRCode()

  // Initial load uses the store's selected difficulties
  await loadLeaderboards()
  await loadOngoingParticipants()

  // Start SignalR connection
  await signalrService.startConnection()

  // Register SignalR handlers and store cleanup functions
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
      // Remove from ongoing participants
      ongoingParticipantsStore.removeParticipant(completion.sessionId)

      // Trigger completion animation
      completionAnimations.value?.handleCompletion(completion)
    })
  )

  // Cleanup inactive participants every 5 seconds
  cleanupInterval = setInterval(() => {
    ongoingParticipantsStore.cleanupInactive()
  }, 5000)

  // Poll for updates every 10 seconds as backup (in case SignalR disconnects or backend restarts)
  pollInterval = setInterval(async () => {
    await loadLeaderboards()
    await loadOngoingParticipants()
  }, 10000)
})

onUnmounted(async () => {
  clearInterval(cleanupInterval)
  clearInterval(pollInterval)

  // Clean up SignalR event handlers
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
    // Fetch ongoing participants for all selected difficulties in parallel
    const diffs = (selectedDifficulties && selectedDifficulties.length) ? selectedDifficulties : ['Christmas']
    const results = await Promise.all(diffs.map((d: string) => api.getOngoingParticipants(d).catch(err => { console.error('ongoing fetch failed for', d, err); return [] })))

    // Merge results and dedupe by sessionId
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

    // Replace the entire participant list with fresh data from the server
    ongoingParticipantsStore.clearAll()
    combined.forEach(participant => ongoingParticipantsStore.addParticipant(participant))
  } catch (error) {
    console.error('Failed to load ongoing participants:', error)
  }
}

const loadLeaderboards = async () => {
  try {
    // Let the store fetch the configured difficulties by default
    await leaderboardStore.fetchLeaderboards()
  } catch {
    // Silently ignore - store handles error state
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
      // Silently ignore QR generation failure
    }
  }
}
</script>

<style scoped lang="scss">
.KioskView {
  // Desktop-only optimizations
  min-width: 1400px; // Minimum width for desktop displays

  // Prevent text selection on kiosk
  user-select: none;
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
}
</style>