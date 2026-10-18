export function scoreGoal(score: number, startingBest: number) {
  const target = score <= startingBest && startingBest > 0 ? startingBest + 10 : (Math.floor(score / 500) + 1) * 500;
  return { target, fraction: Math.min(1, score / target), label: target === startingBest + 10 ? 'Beat your best' : 'Next milestone' };
}
