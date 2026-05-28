//
// Pure TypeScript concurrency limiter. Avoids external dependency bloat
// and provides safe async queuing for CPU-intensive processes like yt-dlp.
//

export function createConcurrencyLimiter(concurrency: number) {
  const queue: (() => void)[] = [];
  let active = 0;

  const next = () => {
    if (queue.length > 0 && active < concurrency) {
      active++;
      const run = queue.shift();
      if (run) run();
    }
  };

  return async <T>(fn: () => Promise<T>): Promise<T> => {
    return new Promise<T>((resolve, reject) => {
      queue.push(() => {
        fn()
          .then(resolve, reject)
          .finally(() => {
            active--;
            next();
          });
      });
      next();
    });
  };
}
