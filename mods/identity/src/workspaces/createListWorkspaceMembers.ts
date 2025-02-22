/*
 * Copyright (C) 2025 by Fonoster Inc (https://fonoster.com)
 * http://github.com/fonoster/fonoster
 *
 * This file is part of Fonoster
 *
 * Licensed under the MIT License (the "License");
 * you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 *    https://opensource.org/licenses/MIT
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import {
  GrpcErrorMessage,
  Validators as V,
  withErrorHandlingAndValidation,
  getAccessKeyIdFromCall
} from "@fonoster/common";
import { getLogger } from "@fonoster/logger";
import {
  ListWorkspaceMembersResponse,
  ListWorkspaceMembersRequest,
  WorkspaceMemberRole,
  WorkspaceMemberStatus
} from "@fonoster/types";
import { ServerInterceptingCall } from "@grpc/grpc-js";
import { Prisma } from "../db";

const logger = getLogger({ service: "identity", filePath: __filename });

function createListWorkspaceMembers(prisma: Prisma) {
  const listWorkspaceMembers = async (
    call: { request: ListWorkspaceMembersRequest },
    callback: (
      error?: GrpcErrorMessage,
      response?: ListWorkspaceMembersResponse
    ) => void
  ) => {
    const { pageSize, pageToken } = call.request;
    const accessKeyId = getAccessKeyIdFromCall(
      call as unknown as ServerInterceptingCall
    );

    logger.verbose("list workspace members", { accessKeyId });

    const workspace = await prisma.workspace.findUnique({
      where: {
        accessKeyId
      }
    });

    const items = await prisma.workspaceMember.findMany({
      where: {
        workspaceRef: workspace.ref
      },
      include: {
        user: true
      },
      take: pageSize,
      skip: pageToken ? 1 : 0,
      cursor: pageToken ? { ref: pageToken } : undefined
    });

    callback(null, {
      items: items.map((item) => ({
        ...item,
        name: item.user.name,
        email: item.user.email,
        role: item.role as WorkspaceMemberRole,
        status: item.status as WorkspaceMemberStatus
      })),
      nextPageToken: items[items.length - 1]?.ref
    });
  };

  return withErrorHandlingAndValidation(
    listWorkspaceMembers,
    V.listRequestSchema
  );
}

export { createListWorkspaceMembers };

// function createListApiKeys(prisma: Prisma) {
//   const listApiKeys = async (
//     call: { request: ListApiKeysRequest },
//     callback: (error: GrpcErrorMessage, response?: ListApiKeysResponse) => void
//   ) => {
//     const { pageSize, pageToken } = call.request;

//     const accessKeyId = getAccessKeyIdFromCall(
//       call as unknown as ServerInterceptingCall
//     );

//     logger.verbose("list keys for workspace", { accessKeyId });

//     const workspace = await prisma.workspace.findUnique({
//       where: {
//         accessKeyId
//       }
//     });

//     const keys = await prisma.apiKey.findMany({
//       where: {
//         workspaceRef: workspace.ref
//       },
//       take: pageSize,
//       skip: pageToken ? 1 : 0,
//       cursor: pageToken ? { ref: pageToken } : undefined
//     });

//     const items = keys.map((key) => ({
//       ...key,
//       role: key.role as ApiRole
//     }));

//     const response: ListApiKeysResponse = {
//       items,
//       nextPageToken: items[items.length - 1]?.ref
//     };

//     callback(null, response);
//   };

//   return withErrorHandlingAndValidation(listApiKeys, V.listRequestSchema);
// }
