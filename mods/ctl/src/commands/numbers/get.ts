/* eslint-disable import/no-unresolved */
/*
 * Copyright (C) 2024 by Fonoster Inc (https://fonoster.com)
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
import * as SDK from "@fonoster/sdk";
import { Args } from "@oclif/core";
import cliui from "cliui";
import moment from "moment";
import { BaseCommand } from "../../BaseCommand";
import { getConfig } from "../../config";
import { CONFIG_FILE } from "../../constants";

export default class Get extends BaseCommand<typeof Get> {
  static override description = "get an Number by reference";
  static override examples = ["<%= config.bin %> <%= command.id %>"];
  static override args = {
    ref: Args.string({ description: "the Number to show details about" })
  };

  public async run(): Promise<void> {
    const { flags } = await this.parse(Get);
    const { args } = await this.parse(Get);
    const workspaces = getConfig(CONFIG_FILE);
    const currentWorkspace = workspaces.find((w) => w.active);

    if (!currentWorkspace) {
      this.error("No active workspace found.");
    }

    const client = new SDK.Client({
      endpoint: currentWorkspace.endpoint,
      accessKeyId: `WO${currentWorkspace.workspaceRef.replaceAll("-", "")}`,
      allowInsecure: flags.insecure
    });

    await client.loginWithApiKey(
      currentWorkspace.accessKeyId,
      currentWorkspace.accessKeySecret
    );

    const numbers = new SDK.Numbers(client);
    const response = await numbers.getNumber(args.ref);

    const apps = new SDK.Applications(client);
    let app;

    try {
      app = await apps.getApplication(response.appRef);
    } catch (e) {
      // You can only try
    }

    const ui = cliui({ width: 200 });

    ui.div(
      "NUMBERS DETAILS\n" +
        "------------------\n" +
        `NAME: \t${response.name}\n` +
        `REF: \t${response.ref}\n` +
        `TEL URL: \t${response.telUrl}\n` +
        `APP: \t${app?.name ?? ""}\n` +
        `APP REF: \t${app?.ref ?? ""}\n` +
        `CITY: \t${response.city}\n` +
        `TRUNK NAME: \t${response.trunk?.name ?? ""}\n` +
        `TRUNK REF: \t${response.trunk?.ref ?? ""}\n` +
        `COUNTRY ISO CODE: \t${response.countryIsoCode}\n` +
        `COUNTRY: \t${response.country}\n` +
        `CREATED: \t${moment(response.createdAt).format("YYYY-MM-DD HH:mm:ss")}\n` +
        `UPDATED: \t${moment(response.updatedAt).format("YYYY-MM-DD HH:mm:ss")}`
    );

    this.log(ui.toString());
  }
}
