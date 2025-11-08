import type { ErrorRequestHandler } from "express";
import { ZodError } from "zod";

import { formatZodError } from "../utils/formatZodError.js";
import { createLogger } from "../utils/logger.js";

const logger = createLogger("error-handler");

export const errorHandler: ErrorRequestHandler = (error, _req, res) => {
  if (error instanceof ZodError) {
    // Respond with structured validation error feedback for clients.
    res.status(400).json({
      message: "Validation failed",
      details: formatZodError(error)
    });
    return;
  }

  // Log unexpected failures while shielding consumers from implementation details.
  logger.error(error, "Unhandled error");

  res.status(500).json({
    message: "Internal server error"
  });
};

