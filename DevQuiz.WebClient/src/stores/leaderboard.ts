import { defineStore } from 'pinia'
import { reactive, ref } from 'vue'
import { api, type LeaderboardEntry } from '@/lib/api'

interface LeaderboardData {
  entries: LeaderboardEntry[]
  loading: boolean
  error: string | null
}

const DEFAULT_DIFFICULTIES = ['Christmas']

export const useLeaderboardStore = defineStore('leaderboard', () => {
  const selectedDifficulties = ref<string[]>([...DEFAULT_DIFFICULTIES])

  const leaderboards = reactive<Record<string, LeaderboardData>>({} as Record<string, LeaderboardData>)

  function initLeaderboards(difficulties: string[]) {
    for (const key of Object.keys(leaderboards)) {
      if (!difficulties.includes(key)) {
        delete (leaderboards as any)[key]
      }
    }

    for (const diff of difficulties) {
      if (!leaderboards[diff]) {
        leaderboards[diff] = {
          entries: [],
          loading: false,
          error: null
        }
      }
    }
  }

  initLeaderboards(selectedDifficulties.value)

  function setDifficulties(difficulties: string[]) {
    selectedDifficulties.value = [...difficulties]
    initLeaderboards(selectedDifficulties.value)
  }

  function ensureLeaderboard(difficulty: string): LeaderboardData {
    if (!leaderboards[difficulty]) {
      leaderboards[difficulty] = {
        entries: [],
        loading: false,
        error: null
      }
    }
    return leaderboards[difficulty]
  }

  async function fetchLeaderboardByDifficulty(difficulty: string, limit: number = 10): Promise<LeaderboardEntry[]> {
    const leaderboardData = ensureLeaderboard(difficulty)

    if (leaderboardData.entries.length === 0) {
      leaderboardData.loading = true
    }
    leaderboardData.error = null

    try {
      const data = await api.getLeaderboard(limit, difficulty)
      leaderboardData.entries = data
      return data
    } catch (err) {
      leaderboardData.error = err instanceof Error ? err.message : 'Failed to load leaderboard'
      throw err
    } finally {
      leaderboardData.loading = false
    }
  }

  async function fetchLeaderboards(difficulties: string[] | null = null, limit: number = 10): Promise<void> {
    const diffs = difficulties ?? selectedDifficulties.value
    await Promise.all(diffs.map(d => fetchLeaderboardByDifficulty(d, limit)))
  }

  function clearLeaderboards() {
    for (const key of Object.keys(leaderboards)) {
      leaderboards[key].entries = []
      leaderboards[key].loading = false
      leaderboards[key].error = null
    }
  }

  function updateLeaderboard(difficulty: string, entries: LeaderboardEntry[]) {
    const leaderboardData = ensureLeaderboard(difficulty)
    leaderboardData.entries = entries
    leaderboardData.loading = false
    leaderboardData.error = null
  }

  function getLeaderboardData(difficulty: string): LeaderboardData {
    return leaderboards[difficulty] ?? { entries: [], loading: false, error: null }
  }

  return {
    selectedDifficulties,
    setDifficulties,

    leaderboards,
    getLeaderboardData,

    fetchLeaderboardByDifficulty,
    fetchLeaderboards,
    clearLeaderboards,
    updateLeaderboard
  }
})