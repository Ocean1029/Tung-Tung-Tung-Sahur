import type {
  LocationCreateInput,
  LocationDeleteResponse,
  LocationDetailResponse,
  LocationListQuery,
  LocationListResponse,
  LocationUpdateInput,
  UserMapQuery,
  UserMapResponse
} from "../types/locations.types.js";
import { prisma } from "../utils/prismaClient.js";

/**
 * Service layer for Locations module
 * Handles all business logic related to location management
 */

const getLocations = async (
  query: LocationListQuery
): Promise<LocationListResponse> => {
  const { page = 1, limit = 100, badge } = query;
  const skip = (page - 1) * limit;

  // Build where clause for badge filtering
  const where: {
    badgeLocationRequirements?: { badgeId: string };
  } = {};

  if (badge) {
    where.badgeLocationRequirements = {
      badgeId: badge
    };
  }

  // Get locations with optional badge filter
  const [locations, totalCount] = await Promise.all([
    prisma.location.findMany({
      where: badge
        ? {
            badgeLocationRequirements: {
              some: {
                badgeId: badge
              }
            }
          }
        : undefined,
      skip,
      take: limit,
      orderBy: {
        createdAt: "desc"
      }
    }),
    prisma.location.count({
      where: badge
        ? {
            badgeLocationRequirements: {
              some: {
                badgeId: badge
              }
            }
          }
        : undefined
    })
  ]);

  return {
    success: true,
    count: totalCount,
    data: locations.map((loc) => ({
      id: loc.id,
      name: loc.name,
      latitude: loc.latitude,
      longitude: loc.longitude,
      description: loc.description,
      nfcId: loc.nfcId,
      isNfcEnabled: loc.isNfcEnabled,
      createdAt: loc.createdAt,
      updatedAt: loc.updatedAt
    }))
  };
};

const createLocation = async (
  input: LocationCreateInput
): Promise<LocationDetailResponse> => {
  // Check if nfcId is already taken if provided
  if (input.nfcId) {
    const existingLocation = await prisma.location.findUnique({
      where: { nfcId: input.nfcId }
    });

    if (existingLocation) {
      throw new Error("NFC ID already exists");
    }
  }

  const location = await prisma.location.create({
    data: {
      name: input.name,
      latitude: input.latitude,
      longitude: input.longitude,
      description: input.description || null,
      isNfcEnabled: input.isNfcEnabled ?? false,
      nfcId: input.nfcId || null
    }
  });

  return {
    success: true,
    data: {
      id: location.id,
      name: location.name,
      latitude: location.latitude,
      longitude: location.longitude,
      description: location.description,
      nfcId: location.nfcId,
      isNfcEnabled: location.isNfcEnabled,
      createdAt: location.createdAt,
      updatedAt: location.updatedAt
    }
  };
};

const updateLocation = async (
  locationId: string,
  input: LocationUpdateInput
): Promise<LocationDetailResponse> => {
  // Check if location exists
  const existingLocation = await prisma.location.findUnique({
    where: { id: locationId }
  });

  if (!existingLocation) {
    throw new Error("Location not found");
  }

  // Check if nfcId is already taken by another location
  if (input.nfcId && input.nfcId !== existingLocation.nfcId) {
    const locationWithNfcId = await prisma.location.findUnique({
      where: { nfcId: input.nfcId }
    });

    if (locationWithNfcId) {
      throw new Error("NFC ID already exists");
    }
  }

  const location = await prisma.location.update({
    where: { id: locationId },
    data: {
      ...(input.name && { name: input.name }),
      ...(input.latitude !== undefined && { latitude: input.latitude }),
      ...(input.longitude !== undefined && { longitude: input.longitude }),
      ...(input.description !== undefined && { description: input.description }),
      ...(input.isNfcEnabled !== undefined && { isNfcEnabled: input.isNfcEnabled }),
      ...(input.nfcId !== undefined && { nfcId: input.nfcId })
    }
  });

  return {
    success: true,
    data: {
      id: location.id,
      name: location.name,
      latitude: location.latitude,
      longitude: location.longitude,
      description: location.description,
      nfcId: location.nfcId,
      isNfcEnabled: location.isNfcEnabled,
      createdAt: location.createdAt,
      updatedAt: location.updatedAt
    }
  };
};

const deleteLocation = async (locationId: string): Promise<LocationDeleteResponse> => {
  // Check if location exists
  const existingLocation = await prisma.location.findUnique({
    where: { id: locationId }
  });

  if (!existingLocation) {
    throw new Error("Location not found");
  }

  await prisma.location.delete({
    where: { id: locationId }
  });

  return {
    success: true,
    message: "點位已成功刪除"
  };
};

const getUserMap = async (query: UserMapQuery): Promise<UserMapResponse> => {
  const { userId, badge, bounds } = query;

  // Verify user exists
  const user = await prisma.user.findUnique({
    where: { id: userId }
  });

  if (!user) {
    throw new Error("User not found");
  }

  // Parse bounds if provided (format: lat1,lng1,lat2,lng2)
  let boundsFilter:
    | {
        latitude?: { gte?: number; lte?: number };
        longitude?: { gte?: number; lte?: number };
      }
    | undefined;

  if (bounds) {
    const [lat1, lng1, lat2, lng2] = bounds.split(",").map(Number);
    const minLat = Math.min(lat1, lat2);
    const maxLat = Math.max(lat1, lat2);
    const minLng = Math.min(lng1, lng2);
    const maxLng = Math.max(lng1, lng2);

    boundsFilter = {
      latitude: {
        gte: minLat,
        lte: maxLat
      },
      longitude: {
        gte: minLng,
        lte: maxLng
      }
    };
  }

  // Get all locations with filters
  const locations = await prisma.location.findMany({
    where: {
      ...(badge && {
        badgeLocationRequirements: {
          some: {
            badgeId: badge
          }
        }
      }),
      ...boundsFilter
    },
    include: {
      userLocationCollections: {
        where: {
          userId
        },
        take: 1,
        orderBy: {
          collectedAt: "desc"
        }
      }
    },
    orderBy: {
      createdAt: "desc"
    }
  });

  // Get user's collected location IDs for quick lookup
  const collectedLocationIds = new Set(
    (
      await prisma.userLocationCollection.findMany({
        where: { userId },
        select: { locationId: true }
      })
    ).map((c) => c.locationId)
  );

  const locationsWithStatus = locations.map((loc) => {
    const isCollected = collectedLocationIds.has(loc.id);
    const collection = loc.userLocationCollections[0];

    return {
      id: loc.id,
      name: loc.name,
      latitude: loc.latitude,
      longitude: loc.longitude,
      description: loc.description,
      nfcId: loc.nfcId,
      isNfcEnabled: loc.isNfcEnabled,
      createdAt: loc.createdAt,
      updatedAt: loc.updatedAt,
      isCollected,
      collectedAt: collection?.collectedAt || null
    };
  });

  return {
    success: true,
    count: locationsWithStatus.length,
    data: {
      locations: locationsWithStatus
    }
  };
};

export const locationsService = {
  getLocations,
  createLocation,
  updateLocation,
  deleteLocation,
  getUserMap
};

