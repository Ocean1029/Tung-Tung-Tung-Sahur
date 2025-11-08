import type { Request, Response } from "express";

import { locationsService } from "../services/locations.service.js";
import { usersService } from "../services/users.service.js";
import type { UserListQuery } from "../types/users.types.js";
import type { UserMapQuery } from "../types/locations.types.js";

/**
 * Controller layer for User Profile module
 * Handles HTTP request/response for user profile endpoints
 */

const getUsers = async (req: Request, res: Response): Promise<void> => {
  const query = req.query as unknown as UserListQuery;
  const result = await usersService.getUsers(query);
  res.status(200).json(result);
};

const getUserProfile = async (req: Request, res: Response): Promise<void> => {
  const { userId } = req.params;
  const result = await usersService.getUserProfile(userId);
  res.status(200).json(result);
};

const getUserMap = async (req: Request, res: Response): Promise<void> => {
  const { userId } = req.params;
  const query = {
    userId,
    ...req.query
  } as UserMapQuery;
  const result = await locationsService.getUserMap(query);
  res.status(200).json(result);
};

export const usersController = {
  getUsers,
  getUserProfile,
  getUserMap
};

