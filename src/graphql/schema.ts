export const typeDefs = /* GraphQL */ `
  type Query {
    health: String!
    userPosition(address: String!): UserPosition!
  }

  type UserPosition {
    address: String!
    totalDeposited: String!
    totalWithdrawn: String!
    currentShares: String!
    lastActivityAt: String!
  }
`;
