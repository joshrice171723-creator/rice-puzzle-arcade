import { useEffect } from 'react';
import { useAudioPlayer } from 'expo-audio';

const tracks: Record<string, number> = {
  'grid-foundry': require('./assets/grid-foundry-music.wav'),
  'merge-drift': require('./assets/merge-drift-music.wav'),
  'color-cascade': require('./assets/color-cascade-music.wav'),
};

export function Music({ slug, playing }: { slug: string; playing: boolean }) {
  const player = useAudioPlayer(tracks[slug]);
  useEffect(() => {
    player.loop = true;
    if (!playing) { player.pause(); player.volume = 0; return; }
    player.volume = 0;
    player.play();
    const fade = setInterval(() => {
      player.volume = Math.min(.32, player.volume + .04);
      if (player.volume >= .32) clearInterval(fade);
    }, 80);
    return () => { clearInterval(fade); player.pause(); };
  }, [player, playing]);
  return null;
}
