Delegate only when tasks are parallelizable, cross-module, need broad exploration, or independent
  review materially lowers risk. High-risk changes must be independently reviewed by an Agent not
  involved in the implementation; if that is impossible, say so. Use parallelism only for
  independent tasks with no overlapping writes; one task is done end-to-end by a single Agent. When
  delegating, specify the goal, context, scope, acceptance criteria, and verification method.