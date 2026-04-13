import { computeUserPosition } from "../reconcile/computeUserPosition";
import fixtures from "../../candidate-pack/fixtures.json";
import { FixtureEvent } from "../reconcile/types";

export const resolvers = {
  Query: {
    health: () => "ok",
    userPosition: (_: any, { address }: { address: string }) => {
      return computeUserPosition(
        address,
        fixtures as FixtureEvent[],
        {} as any,
      );
    },
  },
};
