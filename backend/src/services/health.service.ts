import os from "node:os";

import { prisma } from "../utils/prismaClient.js";

type HealthStatusInput = {
  traceId?: string;
};

type HealthStatus = {
  status: "ok";
  uptime: number;
  hostname: string;
  database: {
    connected: boolean;
  };
  traceId?: string;
};

const getStatus = async ({ traceId }: HealthStatusInput): Promise<HealthStatus> => {
  // Run a lightweight query to verify database connectivity.
  await prisma.$queryRaw`SELECT 1`;

  return {
    status: "ok",
    uptime: process.uptime(),
    hostname: os.hostname(),
    database: {
      connected: true
    },
    traceId
  };
};

export const healthService = {
  getStatus
};

