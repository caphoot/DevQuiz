<template>
  <div class="text-white w-[95%] mx-auto">
    <!-- Duck progress row -->
    <div class="flex flex-row justify-start items-center py-4 gap-0">
      <div class="flex items-center gap-2">
        <template v-if="showDucks">
          <svg
            v-for="duck in totalQuestions"
            :key="duck"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            class="w-6 h-6 transition-all duration-300 scale-x-[-1]"
            :class="{
              'opacity-100 scale-110 fill-yellow-400': duck < displayIndex,
              'opacity-100 scale-110 fill-none stroke-yellow-400 stroke-2': duck === displayIndex,
              'fill-white': duck > displayIndex,
            }"
          >
            <path
              d="M8.5,5A1.5,1.5 0 0,0 7,6.5A1.5,1.5 0 0,0 8.5,8A1.5,1.5 0 0,0 10,6.5A1.5,1.5 0 0,0 8.5,5M10,2A5,5 0 0,1 15,7C15,8.7 14.15,10.2 12.86,11.1C14.44,11.25 16.22,11.61 18,12.5C21,14 22,12 22,12C22,12 21,21 15,21H9C9,21 4,21 4,16C4,13 7,12 6,10C2,10 2,6.5 2,6.5C3,7 4.24,7 5,6.65C5.19,4.05 7.36,2 10,2Z"
            />
          </svg>
        </template>
      </div>

      <span class="ml-4 text-md opacity-90">
        {{ displayIndex }} / {{ totalQuestions }}
      </span>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'

const props = defineProps<{
  currentIndex: number
  totalQuestions: number
  questionType?: 'MultipleChoice' | 'CodeFix'
}>()

// Track window width to determine whether ducks fit
const windowWidth = ref<number>(typeof window !== 'undefined' ? window.innerWidth : 1024)
const duckDisplayWidth = 28 // approx width per duck including gap in px

const updateWidth = () => {
  windowWidth.value = window.innerWidth
}

onMounted(() => {
  window.addEventListener('resize', updateWidth)
})

onUnmounted(() => {
  window.removeEventListener('resize', updateWidth)
})

const availableWidth = computed(() => windowWidth.value * 0.95 - 120) // container ~95% minus space for count
const showDucks = computed(() => props.totalQuestions * duckDisplayWidth <= availableWidth.value && props.totalQuestions <= 20)

const displayIndex = computed(() => props.currentIndex + 1)

const totalQuestions = computed(() => props.totalQuestions)

</script>
