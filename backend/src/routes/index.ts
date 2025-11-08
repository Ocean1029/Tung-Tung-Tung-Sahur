import type { Express } from "express";
import { Router } from "express";

import { healthRouter } from "./health.routes.js";

export const registerRoutes = (app: Express): void => {
  // Aggregate feature routers under a single API namespace for clarity.
  const apiRouter = Router();

  apiRouter.use("/health", healthRouter);

  app.use("/api", apiRouter);
};

