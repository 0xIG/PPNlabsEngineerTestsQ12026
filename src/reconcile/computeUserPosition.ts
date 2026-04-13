import { CandidateConfig, FixtureEvent, UserPosition } from "./types";

export function computeUserPosition(
  user: string,
  fixtures: FixtureEvent[],
  config: CandidateConfig,
): UserPosition {
  let totalDeposited = 0n;
  let totalWithdrawn = 0n;
  let sharesDeposited = 0n;
  let sharesWithdrawn = 0n;
  let currentShares = 0n;
  let lastActivityAt = 0;

  const processedEvents = new Set<string>();

  fixtures.map((event): void => {
    if (event.user.toLowerCase() !== user.toLowerCase()) return;
    const eventKey = `${event.blockNumber}-${event.txHash}:${event.logIndex}`;
    if (processedEvents.has(eventKey)) return;
    processedEvents.add(eventKey);

    const assetsAmount = BigInt(event.assets);
    const sharesAmount = BigInt(event.shares);

    if (event.event === "Deposit") {
      totalDeposited += assetsAmount;
      sharesDeposited += sharesAmount;
      currentShares += sharesAmount;
    } else if (event.event === "Withdraw") {
      totalWithdrawn += assetsAmount;
      sharesWithdrawn += sharesAmount;
      currentShares -= sharesAmount;
    }

    if (event.timestamp > lastActivityAt) {
      lastActivityAt = event.timestamp;
    }
  });

  return {
    address: user.toLowerCase(),
    totalDeposited: totalDeposited.toString(),
    totalWithdrawn: totalWithdrawn.toString(),
    currentShares: currentShares.toString(),
    lastActivityAt: lastActivityAt.toString(),
  };
}
